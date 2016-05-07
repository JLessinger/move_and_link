if [ $1 == "-b" ]; then
    shift;
    echo "shift $1"
    BYPASS=true
else
    BYPASS=false
fi

if [ $1 == "-r" ]; then
    shift;
    echo "shift $1"
    REPLICATE=true
else
    REPLICATE=false
fi
ORIG_PATH=$1
NEW_FOLDER=$2

function go {
    DIR=`dirname $NEW_PATH`
    mkdir -p $DIR
    mv $ORIG_PATH $NEW_FOLDER && ln -s `realpath $NEW_PATH` $LNK
    if [ $? -ne 0 ]; then
	printf "usage: ./move_and_link.sh [-b] [-r] original_file new_folder\n
\t-b : bypass interactive confirmation; just execute\n
\t-r: replicate structure\n
\t\t e.g. ./move_and_link.sh -r /some/path /disk2/data/root/\n
\t\t moves /some/path to /disk2/data/root/some/path\n"
	exit 1
    fi
}

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


