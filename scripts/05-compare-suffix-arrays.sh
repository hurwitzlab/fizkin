#!/bin/bash

#
# Run tallymer search for every read against every index
#

source ./config.sh

CWD=$PWD
PROG=`basename $0 ".sh"`
ERR_DIR=$CWD/err/$PROG
OUT_DIR=$CWD/out/$PROG

create_dirs $ERR_DIR $OUT_DIR

if [[ ! -d $COUNT_DIR ]]; then
    mkdir $COUNT_DIR
fi

export INDEX_FILE=$SUFFIX_DIR/index-files

if [[ ! -e $INDEX_FILE ]]; then
    echo Index file "$INDEX_FILE" is missing!
    exit
fi

echo Processing reads in $FASTA_DIR
i=0
cd $FASTA_DIR

#
# Sample directories will be like "POV_GD.Spr.C.8m_reads"
#
d=0
for SAMPLE_DIR in `find . -maxdepth 1 -type d | sort`; do
    d=$((d+1))
    if [ "$SAMPLE_DIR" = '.' ]; then
        continue
    fi

    cd $SAMPLE_DIR

    #
    # Subtract the "." directory
    #
    NUM_JOBS=`find . -maxdepth 1 -type d | wc -l`
    NUM_JOBS=$(($NUM_JOBS-1))

    if [ $NUM_JOBS -eq 0 ]; then
        continue;
    fi

    export SAMPLE_DIR
    export CWD=$PWD
    export SAMPLE1=`basename $SAMPLE_DIR`
    DEST_DIR_BASE=$COUNT_DIR/$SAMPLE1/$READS_DIR

    if [ -d $DEST_DIR_BASE ]; then
        echo Cleaning out $DEST_DIR_BASE
        find $DEST_DIR_BASE -type f -name \*.count -exec rm {} \;
    else 
        mkdir -p $DEST_DIR_BASE
    fi

    while read INDEX_LIST; do
        export SAMPLE2=`basename \`dirname $INDEX_LIST\``
        export DEST_DIR=$DEST_DIR_BASE/$SAMPLE2
        export INDEX_LIST

        if [[ ! -d $DEST_DIR ]]; then
            mkdir $DEST_DIR
        fi

        JOB_ID=`qsub -N sa_compare -e $ERR_DIR/$SAMPLE_DIR.$i -o $OUT_DIR/$SAMPLE_DIR.$i -J 1-$NUM_JOBS -v SCRIPT_DIR,DEST_DIR,SAMPLE1,SAMPLE2,GT,INDEX_LIST,CWD,SAMPLE_DIR $SCRIPT_DIR/sa_compare.sh`

        i=$((i+1))
        printf "%8d: %s -> %s (%s)" $i $READ_NAME $SAMPLE1 $SAMPLE2 $JOB_ID
        echo
    done < $INDEX_FILE

    cd ..

    if [ $d -eq 2 ]; then
        break
    fi
done

echo Submitted $i jobs for you.  Namaste.
