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

    export CWD=$PWD
    export SAMPLE1=`basename $SAMPLE_DIR`

    #
    # Read directory names will be "00," "01" from split FASTA files
    #
    for READS_DIR in `find . -maxdepth 1 -type d | sort`; do
        if [ "$READS_DIR" == '.' ]; then
            continue
        fi

        DEST_DIR_BASE=$COUNT_DIR/$SAMPLE1/$READS_DIR

        if [ -d $DEST_DIR_BASE ]; then
            echo Cleaning out $DEST_DIR_BASE
            find $DEST_DIR_BASE -type f -name \*.count -exec rm {} \;
        else 
            mkdir -p $DEST_DIR_BASE
        fi

        export READS_DIR

        for INDEX_LIST in `cat $INDEX_FILE`; do
            export SAMPLE2=`basename \`dirname $INDEX_LIST\``
            export DEST_DIR=$DEST_DIR_BASE/$SAMPLE2
            export INDEX_LIST

            if [[ ! -d $DEST_DIR ]]; then
                mkdir $DEST_DIR
            fi

            i=$((i+1))
            printf "%10d: %s %s %s" $i $READ_NAME $SAMPLE1 $SAMPLE2
            echo

            #qsub -N sa_compare -e $ERR_DIR/$READS_DIR.$i -o $OUT_DIR/$READS_DIR.$i -v SCRIPT_DIR,DEST_DIR,SAMPLE1,SAMPLE2,GT,INDEX_LIST,CWD,READS_DIR $SCRIPT_DIR/sa_compare.sh
            #break
        done

        #if [ $i -gt 50 ]; then
        #    break
        #fi
    done

    #break
done

echo Submitted $i jobs for you.  Namaste.

        #
        # Read file names will be sequence IDs, e.g., "GON5MYK01BCZTK.fa"
        #
#        cd $READS_DIR
#        for READ in `ls *.fa`; do
#            export READ_NAME=`basename $READ ".fa"`
#            export READ_PATH=`readlink -f $PWD/$READ`
#
#            JOB_ID=`qsub -N sa_compare -e $ERR_DIR/$SAMPLE1-$READ_NAME -o $OUT_DIR/$SAMPLE1-$READ_NAME -v COUNT_DIR,SAMPLE1,GT,INDEX_FILE,READ_NAME,READ_PATH $SCRIPT_DIR/sa_compare.sh`
#
#            i=$((i+1))
#            printf "%10d: %s %s -> %s" $i $SAMPLE1 $READ_NAME $JOB_ID
#            echo
#            break
#        done
#
#        cd ..
#        break
