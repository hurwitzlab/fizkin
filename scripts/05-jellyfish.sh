#!/bin/bash

#
# Run tallymer search for every read against every index
#

source ./config.sh
export FASTA_DIR="$BASE_DIR/data/full_fasta"

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
for SAMPLE_DIR in `find . -maxdepth 1 -type d | sort`; do
    d=$((d+1))
    if [ "$SAMPLE_DIR" = '.' ]; then
        continue
    fi

    for FASTA_FILE in *.fa; do
        i=$((i+1))
        printf "%8d: %s -> %s (%s)" $i $READ_NAME $SAMPLE1 $SAMPLE2 $JOB_ID
        echo
        JOB_ID=`qsub -N sa_compare -e "$ERR_DIR/$SAMPLE_DIR.$i" -o "$OUT_DIR/$SAMPLE_DIR.$i" -v SCRIPT_DIR,DEST_DIR,SAMPLE1,SAMPLE2,GT,INDEX_LIST,CWD,SAMPLE_DIR $SCRIPT_DIR/jellyfish.sh`
    done

    cd $SAMPLE_DIR
done

echo Submitted $i jobs for you.  Namaste.
