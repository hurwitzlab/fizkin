#!/bin/bash

# 
# Prepare a directory structure for every read-to-read count
# 

source ./config.sh
export CWD="$PWD"

PROG=`basename $0 ".sh"`
ERR_DIR="$CWD/err/$PROG"
OUT_DIR="$CWD/out/$PROG"

create_dirs "$ERR_DIR" "$OUT_DIR"

echo Checking kmer dir \"$KMER_DIR\"
if [[ ! -d $KMER_DIR ]]; then
    mkdir $KMER_DIR
fi

echo Processing files in \"$FASTA_DIR\"
cd $FASTA_DIR

i=0
for FASTA in *.*; do
    export FILE=`readlink -f $FASTA`

    JOB_ID=`qsub -N kmerizer -e "$ERR_DIR/$FASTA" -o "$OUT_DIR/$FASTA" -v SCRIPT_DIR,MER_SIZE,FILE,KMER_DIR $SCRIPT_DIR/launch-kmerizer.sh`

    i=$((i+1))
    printf "%5d: %s\n" $i $FASTA
done
