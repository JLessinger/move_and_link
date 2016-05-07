USG_MSG="usage: ./move_and_link.sh [-b] [-r] [ -i link | original_file new_folder ]\n
\t-b : bypass interactive confirmation; just execute\n
\t-r: replicate structure\n
\t-i: if this is passed with a soft link, moves its target back to the link's location.
\t\t e.g. ./move_and_link.sh -r /some/path /disk2/data/root/\n
\t\t moves /some/path to /disk2/data/root/some/path\n\n"

function go {    
    if [ -z $LINK_TO_INVERT ]; then
	ORIG_PATH=$1
	NEW_FOLDER=$2

	ITEM=`basename $ORIG_PATH`
	if [ "$REPLICATE" == true ] ; then
	    NEW_FOLDER=${NEW_FOLDER%/}/`dirname $ORIG_PATH`  
	fi
	NEW_PATH=${NEW_FOLDER%/}/$ITEM

	if [ "$BYPASS" == false ] ; then
	    printf "move $ORIG_PATH to $NEW_PATH? (y/n)\n"
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
	LNK=${ORIG_PATH%/}

	DIR=`dirname $NEW_PATH`
	mkdir -p $DIR
	mv $ORIG_PATH $NEW_FOLDER && ln -s `realpath $NEW_PATH` $LNK
	if [ $? -ne 0 ]; then
	    printf "$USG_MSG"
	    exit 1
	fi
    else
	FROM=`ls -l $LINK_TO_INVERT | awk '{print $11}'`
	TO=$LINK_TO_INVERT
	if [ "$BYPASS" == false ] ; then
	    printf "move $FROM to $TO? (y/n)\n"
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
	mv $FROM $TO
    fi
}

# A POSIX variable
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
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

go "$@"
