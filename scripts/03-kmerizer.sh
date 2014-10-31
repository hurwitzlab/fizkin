#!/bin/bash

# 
# Prepare a directory structure for every read-to-read count
# 

source ./config.sh
export CWD=$PWD

PROG=`basename $0 ".sh"`
ERR_DIR=$CWD/err/$PROG
OUT_DIR=$CWD/out/$PROG

create_dirs "$ERR_DIR" "$OUT_DIR"

echo Checking kmer dir \"$KMER_DIR\"
if [[ ! -d $KMER_DIR ]]; then
    mkdir $KMER_DIR
fi

echo Processing files in \"$FULL_FASTA_DIR\"
cd $FULL_FASTA_DIR

i=0
for FILE in *.*; do
    export FILE
    JOB_ID=`qsub -N kmerizer -e "$ERR_DIR/$FILE" -o "$OUT_DIR/$FILE" -v MER_SIZE,FILE,KMER_DIR $SCRIPT_DIR/launch-kmerizer.sh`
    i=$((i+1))
    printf '%8d: %s' $i $FILE
    echo
done
