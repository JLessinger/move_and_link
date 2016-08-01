#!/usr/bin/env bash

USG_MSG="usage: ./move_and_link.sh [-b] [-r [-t]] [ -I link | original_file new_folder ]
\t-b : bypass interactive confirmation; just execute
\t-r: replicate structure
\t\t e.g. ./move_and_link.sh -r /some/path /disk2/data/root/
\t\t moves /some/path to /disk2/data/root/some/path
\t-t: if replicating structure, replicate only relative path given as input. By default,
\t\treplicate absolute path (from root down to the item)
\t-i: inverse. if passed with a soft link, moves its target back to the link's location.
\t\tIf other arguments given, inverts the corresponding move-and-link operation.\n
names with special characters, including whitespace, not supported!\n"

function abort {
    printf "$1" >&2
    exit 1
}

#  in:
#    PATH1, PATH2
#  out:
#    nothing
#  side effects:
#    cancels with status 0 iff not confirmed
function confirm {
    if [ "$BYPASS" == false ] ; then
	printf "move $1 to $2? (y/n)\n"
	read resp
	resp=${resp,,}
	case "$resp" in
	    y|ye|yes) # pass through
	    ;;
	    *) printf "canceling\n"
	       exit 0
	       ;;
	esac
    fi
}

function verify_confirm_execute {
    if ! $ABSOLUTE && ! $REPLICATE ; then
	# -t flag was given but replicate was not. This doesn't mean anything.
	abort "$USG_MSG"
    fi
    
    if [ -z $LINK_TO_INVERT ]; then
	if [ -L $1 ] || ! ( [ -f $1 ] || [ -d $1 ] ); then
	    abort "source path missing or wrong type (is it already a link?)\n"
	fi
	confirm_execute "$@"
    else
	if ! [ -L $LINK_TO_INVERT ]; then
	    abort "source must be a symbolic link\n"
	fi
	confirm_execute_inverse "$@"
    fi
}

#  in: script args
#  out: nothing
#  side effects: set switch vars, remove switches from script args
function parse_verify_confirm_execute {
    # Reset in case getopts has been used previously in the shell.
    OPTIND=1         

    # Initialize our own variables:
    BYPASS=false
    REPLICATE=false
    ABSOLUTE=true

    while getopts "hbrti:" opt; do
	case "$opt" in
            h)
		printf "$USG_MSG"
		exit 0 ;;
            b)
		BYPASS=true ;;
            r)
		REPLICATE=true ;;
	    t)
		ABSOLUTE=false ;;
            i)
		LINK_TO_INVERT=${OPTARG%/} ;;
	    *)
		abort "$USG_MSG"
	esac
    done

    shift $((OPTIND-1))

    [ "$1" = "--" ] && shift

    # get rid of trailing / to make the rest easier
    args=( "$@" )
    args[0]="${1%/}"
    args[1]="${2%/}"
    set "${args[@]}"
    verify_confirm_execute "$@"
}

function confirm_execute {
    ORIG_PATH=$1
    NEW_FOLDER=$2

    ITEM=`basename $ORIG_PATH`
    if [ "$REPLICATE" == true ] ; then
	if [ "$ABSOLUTE" == true ] ; then
	    REP_PATH=`realpath $ORIG_PATH`
	else
	    REP_PATH=$ORIG_PATH
	fi
	NEW_FOLDER=${NEW_FOLDER%/}/`dirname $REP_PATH`  
    fi
    NEW_PATH=${NEW_FOLDER%/}/$ITEM


    LNK=${ORIG_PATH%/}

    confirm $ORIG_PATH $NEW_PATH

    DIR=`dirname $NEW_PATH`
    mkdir -p $DIR
    mv $ORIG_PATH $NEW_FOLDER && ln -s `realpath $NEW_PATH` $LNK
    if [ $? -ne 0 ]; then
	abort
    fi
}

function confirm_execute_inverse {
    FROM=`ls -l $LINK_TO_INVERT | awk '{print $11}'`
    TO=`dirname $LINK_TO_INVERT`
    DATE=`date +%s`
    RND=`echo $LINK_TO_INVERT.$DATE | md5`
    TMPLNK=$LINK_TO_INVERT.$RND

    confirm $FROM $TO

    mv $LINK_TO_INVERT $TMPLNK
    mv $FROM $TO
    if [ $? -ne 0 ]; then
	abort 
    fi
    rm $TMPLNK
}

parse_verify_confirm_execute "$@"
