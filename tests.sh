TESTROOT=./testdir

function link_target_relative {
    echo `ls -l $1 | awk '{print $11}'`
}

function types_correct {
    EXPECTED_TARGET=$1
    LNK=$2
    if (! [ -h $LNK ] || ! ( [ -f $EXPECTED_TARGET ] || [ -d $EXPECTED_TARGET ])); then
	return 1
    else
	return 0
    fi
}

function link_correct {
    EXPECTED_TARGET=$1
    LNK=$2

    TARGET=`link_target_relative "$2"`
    # if [ "$EXPECTED_TARGET" = "$TARGET" ]; then
    if [ "$EXPECTED_TARGET" -ef "$TARGET" ]; then
	return 0
    else
	return 1
    fi
}

function check_file_count_differences {
    ROOT1=$1
    ROOT2=$2
    EXPF=$3
    EXPD=$4
    EXPL=$5
    # all counts are 2 - 1 (dest - source)
    FC1=`find $ROOT1 -type f | wc -l`
    FC2=`find $ROOT2 -type f | wc -l`
    DC1=`find $ROOT1 -type d | wc -l`
    DC2=`find $ROOT2 -type d | wc -l`
    LC1=`find $ROOT1 -type l | wc -l`
    LC2=`find $ROOT2 -type l | wc -l`
    a1=$(( $FC2 - $FC1 - $EXPF ))
    a2=$(( $DC2 - $DC1 - $EXPD ))
    a3=$(( $LC2 - $LC1 - $EXPL ))
    if ( [ $a1 -eq 0 ] && [ $a2 -eq 0 ] && [ $a3 -eq 0 ] ); then
	return 0
    else
	return 1
    fi
}

#  in:
#    relative source dir
#    item
#    item type (f, d, etc.)
#    relative dest dir
#    F diff (file)
#    D diff (dir)
#    L diff (sym link)
#  out:
#    none
#    side effects: runs the test, prints results
function do_test {
    SOURCEDIR=$TESTROOT/$1
    ITEM=$2
    TYPE=$3
    SOURCEPATH=$SOURCEDIR/$ITEM
    # the root of the destination 
    DESTDIR=$TESTROOT/$4
    # the full target path
    TARGET=$DESTDIR/$ITEM
    mkdir -p $SOURCEDIR
    case "$TYPE" in
	f) touch $SOURCEPATH ;;
	d) mkdir $SOURCEPATH ;;
	*) exit 1
    esac

 
    sleep .5

    if ! [ -z $4 ] && [ $4 = '-r' ]; then
	run ./move_and_link.sh -b -r $SOURCEPATH $DESTDIR
    else
	run ./move_and_link.sh -b $SOURCEPATH $DESTDIR
    fi
    
    [ "$status" -eq 0 ]

    sleep .5

    TYPES=$(types_correct $TARGET $SOURCEPATH)
    [[ $TYPES -eq 0 ]]

    LNK=$(link_correct $TARGET $SOURCEPATH)
    [[ $LNK -eq 0 ]]

    DIFF=$(check_file_count_differences "$SOURCEDIR" "$DESTDIR" $5 $6 $7)
    [[ $DIFF -eq 0 ]]
}

function setup() {
    rm -rf $TESTROOT
}

@test "not r, file, not exists" {
    RELSRC=disk1/users/jonathan/somedir
    ITEM=f
    RELDEST=disk2/disk1data/users/jonathan/somedir
    do_test $RELSRC $ITEM f $RELDEST 1 0 -1
}

@test "not r, file, parent exists" {
    RELSRC=disk1/users/jonathan/somedir
    ITEM=f
    RELDEST=disk2/disk1data/users/jonathan/somedir
    mkdir -p $TESTROOT/$RELDEST
    do_test $RELSRC $ITEM f $RELDEST 1 0 -1
}

@test "not r, file, item exists" {
    RELSRC=disk1/users/jonathan/somedir
    ITEM=f
    RELDEST=disk2/disk1data/users/jonathan/somedir
    mkdir -p $TESTROOT/$RELDEST
    touch $TESTROOT/$RELDEST/$ITEM
    do_test $RELSRC $ITEM f $RELDEST 1 0 -1
}

@test "not r, folder, not exists" {
    RELSRC=disk1/users/jonathan
    ITEM=somedir
    RELDEST=disk2/disk1data/users/jonathan
    do_test $RELSRC $ITEM d $RELDEST 0 1 -1
}

@test "not r, folder, parent exists" {
    RELSRC=disk1/users/jonathan
    ITEM=somedir
    RELDEST=disk2/disk1data/users/jonathan
    mkdir -p $TESTROOT/$RELDEST
    do_test $RELSRC $ITEM d $RELDEST 0 1 -1
}

@test "not r, folder, item exists" {
    RELSRC=disk1/users/jonathan
    ITEM=somedir
    RELDEST=disk2/disk1data/users/jonathan
    mkdir -p $TESTROOT/$RELDEST
    mkdir $TESTROOT/$RELDEST/$ITEM
    do_test $RELSRC $ITEM d $RELDEST 0 1 -1
}
