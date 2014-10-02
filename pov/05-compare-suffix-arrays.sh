#!/bin/bash

#
# Run tallymer search for every read against every index
#

source ./config.sh

export CWD=$PWD

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
for SAMPLE_DIR in `find . -maxdepth 1 -type d | sort`; do
    if [ "$SAMPLE_DIR" = '.' ]; then
        continue
    fi

    cd $SAMPLE_DIR

    export SAMPLE1=`basename $SAMPLE_DIR`

    #
    # Read directory names will be "00," "01" from split FASTA files
    #
    for READS_DIR in `find . -maxdepth 1 -type d | sort`; do
        if [ "$READS_DIR" = '.' ]; then
            continue
        fi

        cd $READS_DIR

        #
        # Read file names will be sequence IDs, e.g., "GON5MYK01BCZTK.fa"
        #
        for READ in `ls *.fa`; do
            export READ_NAME=`basename $READ ".fa"`
            export READ_PATH=`readlink -f $PWD/$READ`

            JOB_ID=`qsub -N sa_compare -e $ERR_DIR/$SAMPLE1-$READ_NAME -o $OUT_DIR/$SAMPLE1-$READ_NAME -v COUNT_DIR,SAMPLE1,GT,INDEX_FILE,READ_NAME,READ_PATH $SCRIPT_DIR/sa_compare.sh`

            i=$((i+1))
            printf "%10d: %s %s -> %s" $i $SAMPLE1 $READ_NAME $JOB_ID
            echo
            #break
        done

        cd ..
        #break
    done

    break
done

echo Submitted $i jobs for you.  Namaste.
