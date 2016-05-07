USG_MSG="usage: ./move_and_link.sh [-b] [-r] original_file new_folder\n
\t-b : bypass interactive confirmation; just execute\n
\t-r: replicate structure\n
\t\t e.g. ./move_and_link.sh -r /some/path /disk2/data/root/\n
\t\t moves /some/path to /disk2/data/root/some/path\n\n"

function go {
    DIR=`dirname $NEW_PATH`
    mkdir -p $DIR
    mv $ORIG_PATH $NEW_FOLDER && ln -s `realpath $NEW_PATH` $LNK
    if [ $? -ne 0 ]; then
	printf "$USG_MSG"
	exit 1
    fi
}

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
BYPASS=false
REPLICATE=false

while getopts "hbr" opt; do
    case "$opt" in
	h)
	    printf "$USG_MSG"
	    exit 0 ;;
	b)
	    BYPASS=true ;;
	r)
	    REPLICATE=true ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift


ORIG_PATH=$1
NEW_FOLDER=$2

ITEM=`basename $ORIG_PATH`
if [ "$REPLICATE" == true ] ; then
    NEW_FOLDER=${NEW_FOLDER%/}/`dirname $ORIG_PATH`  
fi
NEW_PATH=${NEW_FOLDER%/}/$ITEM

LNK=${ORIG_PATH%/}

if [ "$BYPASS" == true ] ; then
    go
else
    printf "move $ORIG_PATH to $NEW_PATH? (y/n)\n"
    read resp
    resp=${resp,,}
    case "$resp" in
	y|ye|yes) go ;;
	*) printf "canceling\n" ;;
    esac
fi


