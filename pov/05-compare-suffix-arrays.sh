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

echo Processing reads
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
    #echo "SAMPLE1 ($SAMPLE1)"
    #echo "INDEX_FILE ($INDEX_FILE)"

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
            export READ
            i=$((i+1))
            echo `printf "%5d: %s/%s" $i $SAMPLE1 $READ`
            READ_NAME=`basename $READ ".fa"`
            #echo "READ_NAME ($READ_NAME)"

            for INDEX_LIST in `cat $INDEX_FILE`; do
                export INDEX_LIST
                #echo INDEX_LIST $INDEX_LIST
                SAMPLE2=`basename \`dirname $INDEX_LIST\``
                #echo "SAMPLE2 ($SAMPLE2)"
                export DEST_DIR=`readlink -f $COUNT_DIR/$SAMPLE1/$SAMPLE2/$READ_NAME`

                if [[ ! -d $DEST_DIR ]]; then
                    mkdir -p $DEST_DIR
                fi

                export CWD=$PWD

                #echo CWD $CWD
                #echo DEST_DIR $DEST_DIR
                #echo GT $GT
                #echo READ $READ

                qsub -N sa_compare -e $ERR_DIR/$READ_NAME -o $OUT_DIR/$READ_NAME -v CWD,GT,INDEX_LIST,READ,DEST_DIR $SCRIPT_DIR/sa_compare.sh
                break
            done

            break
        done

        cd ..
        break
    done

    break
done
