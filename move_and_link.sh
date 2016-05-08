USG_MSG="usage: ./move_and_link.sh [-b] [-r] [ -i link | original_file new_folder ]
\t-b : bypass interactive confirmation; just execute
\t-r: replicate structure
\t\t e.g. ./move_and_link.sh -r /some/path /disk2/data/root/
\t\t moves /some/path to /disk2/data/root/some/path
\t-i: inverse. if passed with a soft link, moves its target back to the link's location.\n
names with special characters, including whitespace, not supported!\n"

function abort {
    printf "$USG_MSG" >&2
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
    if [ -z $LINK_TO_INVERT ]; then
	if ! ( [ -f $1 ] || [ -d $1 ] ); then
	    abort
	fi
	confirm_execute "$@"
    else
	if ! [ -h $LINK_TO_INVERT ]; then
	    abort
	fi
	confirm_execute_inverse "$@"
    fi
}

#  in: script args
#  out: nothing
#  side effects: set switch vars, remove switches from script args
function parse_verify_confirm_execute {
    OPTIND=1         # Reset in case getopts has been used previously in the shell.

    # Initialize our own variables:
    BYPASS=false
    REPLICATE=false

    while getopts "hbri:" opt; do
	case "$opt" in
            h)
		printf "$USG_MSG"
		exit 0 ;;
            b)
		BYPASS=true ;;
            r)
		REPLICATE=true ;;
            i)
		LINK_TO_INVERT=$OPTARG ;;
	    *)
		abort
	esac
    done

    shift $((OPTIND-1))

    [ "$1" = "--" ] && shift

    verify_confirm_execute "$@"
}

function confirm_execute {
    ORIG_PATH=$1
    NEW_FOLDER=$2

    ITEM=`basename $ORIG_PATH`
    if [ "$REPLICATE" == true ] ; then
	NEW_FOLDER=${NEW_FOLDER%/}/`dirname $ORIG_PATH`  
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
    TO=$LINK_TO_INVERT

    confirm $FROM $TO
    
    mv $FROM $TO
    if [ $? -ne 0 ]; then
	abort 
    fi
}

parse_verify_confirm_execute "$@"
