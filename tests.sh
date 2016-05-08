TESTROOT=./testdir
DEBUGFILE=debug.txt #stdout and stderr
function log_debug_info {
    echo $1 >> $DEBUGFILE
}

function link_target_relative {
    echo `ls -l $1 | awk '{print $11}'`
}

function types_correct {
    EXPECTED_TARGET=$1
    SOURCE_PATH=$2
    INVERSE=$3
    if [ "$INVERSE" = true ]; then
	if [ -f $EXPECTED_TARGET ] || [ -L $SOURCE_PATH ] || ! ([ -f $SOURCE_PATH ] || [ -d $SOURCE_PATH ]); then
	    # either the file was not moved back, or the source is still a link, or the source does not exist
	    return 1
	else
	    return 0
	fi
    else
	if (! [ -L $SOURCE_PATH ] || ! ( [ -f $EXPECTED_TARGET ] || [ -d $EXPECTED_TARGET ])); then
	    return 1
	else
	    return 0
	fi
    fi

}

function link_correct {
    EXPECTED_TARGET=$1
    LNK=$2
    INVERSE=$3
    if [ $INVERSE = true ]; then
	# there is no link to check
	return 0
    fi

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
#    replicate
#    inverse
#  out:
#    none
#    side effects: runs the test, prints results
function do_test {
    REPLICATE=false
    INVERSE=false
    if (! [ -z $8 ] && [ $8 = '-r' ]) || (! [ -z $9 ] && [ $9 = '-r' ]); then
	REPLICATE=true
    fi
    if (! [ -z $8 ] && [ $8 = '-i' ]) || (! [ -z $9 ] && [ $9 = '-i' ]); then
	INVERSE=true
    fi
    SOURCEDIR=$TESTROOT/$1
    ITEM=$2
    TYPE=$3
    SOURCEPATH=$SOURCEDIR/$ITEM
    # the root of the destination 
    DESTDIR=$TESTROOT/$4
    # the complete relative target path from here (script wd)
    if [ "$REPLICATE" = true ]; then
	TARGET=$DESTDIR/$SOURCEPATH
    else
	TARGET=$DESTDIR/$ITEM
    fi
    mkdir -p $SOURCEDIR

    case "$TYPE" in
	f) touch $SOURCEPATH ;;
	d) mkdir -p $SOURCEPATH ;; # redundant, but won't complain if ITEM exists already
	*) exit 1
    esac

    if [ "$INVERSE" = true ]; then
	mkdir -p $DESTDIR
	# since it's inverted, these are swapped
	TMP=$SOURCEPATH
	SOURCEPATH=$TARGET
	TARGET=$TMP

	# these is used later (file count differences)
	TMP=$SOURCEDIR
	SOURCEDIR=$DESTDIR
	DESTDIR=$TMP
	
	ln -s $TARGET $SOURCEPATH
    fi

    sleep .1

    if [ "$INVERSE" = true ]; then
	run ./move_and_link.sh -b -i $SOURCEPATH
    else
	if [ "$REPLICATE" = true ]; then
	    run ./move_and_link.sh -b -r $SOURCEPATH $DESTDIR
	else
	    run ./move_and_link.sh -b $SOURCEPATH $DESTDIR
	fi
    fi

    log_debug_info "run output=$output\n"
    log_debug_info "run status=$status\n"
    [ "$status" -eq 0 ]

    sleep .1

    TYPES=$(types_correct $TARGET $SOURCEPATH $INVERSE)
    [[ $TYPES -eq 0 ]]

    LNK=$(link_correct $TARGET $SOURCEPATH $INVERSE)
    [[ $LNK -eq 0 ]]

    DIFF=$(check_file_count_differences "$SOURCEDIR" "$DESTDIR" $5 $6 $7)
    [[ $DIFF -eq 0 ]]
}

function setup() {
    rm -rf $TESTROOT
}

@test "inverse file" {
    RELSRC=disk1/users/jonathan/somedir
    ITEM=f
    RELDEST=disk2/disk1data/users/jonathan/somedir
    do_test $RELSRC $ITEM f $RELDEST -1 0 0 -i
}

@test "inverse folder" {
    RELSRC=disk1/users/jonathan/somedir
    ITEM=f
    RELDEST=disk2/disk1data/users/jonathan/somedir
    do_test $RELSRC $ITEM d $RELDEST 0 -1 0 -i
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

#  with -r

@test "r, file, not exists" {
    RELSRC=disk1/users/jonathan/somedir
    ITEM=f
    RELDEST=disk2/disk1data/
    # folder diff should be the 4 in RELSRC plus TESTROOT, which is part of the source path.
    do_test $RELSRC $ITEM f $RELDEST 1 5 -1 -r
}

@test "r, file, parent exists" {
    RELSRC=disk1/users/jonathan/somedir
    ITEM=f
    RELDEST=disk2/disk1data
    mkdir -p $TESTROOT/$RELDEST/$TESTROOT/$RELSRC
    do_test $RELSRC $ITEM f $RELDEST 1 5 -1 -r
}

@test "r, file, item exists" {
    RELSRC=disk1/users/jonathan/somedir
    ITEM=f
    RELDEST=disk2/disk1data
    mkdir -p $TESTROOT/$RELDEST/$TESTROOT/$RELSRC
    touch $TESTROOT/$RELDEST/$TESTROOT/$RELSRC/$ITEM
    do_test $RELSRC $ITEM f $RELDEST 1 5 -1 -r
}

@test "r, folder, not exists" {
    RELSRC=disk1/users/jonathan
    ITEM=somedir
    RELDEST=disk2/disk1data
    # folder diff count = 3 for RELSRC + 1 for TESTROOT + 1 for ITEM
    do_test $RELSRC $ITEM d $RELDEST 0 5 -1 -r
}

@test "r, folder, parent exists" {
    RELSRC=disk1/users/jonathan
    ITEM=somedir
    RELDEST=disk2/disk1data
    mkdir -p $TESTROOT/$RELDEST/$TESTROOT/$RELSRC
    do_test $RELSRC $ITEM d $RELDEST 0 5 -1 -r
}

@test "r, folder, item exists" {
    RELSRC=disk1/users/jonathan
    ITEM=somedir
    RELDEST=disk2/disk1data
    mkdir -p $TESTROOT/$RELDEST/$TESTROOT/$RELSRC/$ITEM
    do_test $RELSRC $ITEM d $RELDEST 0 5 -1 -r
}

@test "r, dir substructure, not exist" {
    RELSRC=users/jonathan/documents/
    ITEM=d1
    RELDEST=disk2/machd
    #  make some other substructure
    mkdir -p $TESTROOT/$RELSRC/$ITEM/d2
    touch $TESTROOT/$RELSRC/$ITEM/f1
    touch  $TESTROOT/$RELSRC/$ITEM/d2/f2
    # now go
    # remember to count the additional subfolders and files, which should appear
    # only in the destination hierarchy.
    do_test $RELSRC $ITEM d $RELDEST 2 6 -1 -r
}


