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

if [[ ! -d "$COUNT_DIR" ]]; then
    mkdir "$COUNT_DIR"
fi

export INDEX_FILE=$SUFFIX_DIR/index-files

if [[ ! -e "$INDEX_FILE" ]]; then
    echo Index file "$INDEX_FILE" is missing!
    exit
fi

echo Processing reads in $FULL_FASTA_DIR
cd $FULL_FASTA_DIR

#
# Sample directories will be like "POV_GD.Spr.C.8m_reads"
#
i=0
for FILE in *.fa; do
    export FASTA_FILE="$FULL_FASTA_DIR/$FILE"

    JOB_ID=`qsub -N "jf_query" -e "$ERR_DIR/$FILE" -o "$OUT_DIR/$FILE" -v SCRIPT_DIR,JELLYFISH_DIR,COUNT_DIR,MER_SIZE,JELLYFISH,FASTA_FILE $SCRIPT_DIR/jellyfish-query.sh`

    i=$((i+1))
    printf "%8d: %s %s\n" $i $JOB_ID $FILE
done

echo Submitted $i jobs for you.  Namaste.
