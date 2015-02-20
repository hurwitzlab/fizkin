#!/bin/bash

# This script runs illumina QC on a directory
# of fastq files, runs the paired read analysis,
# then creates fasta/qual files from the paired
# fastq files

source ./config.sh

export CWD="$PWD"

PROG=`basename $0 ".sh"`
ERR_DIR=$CWD/err/$PROG
OUT_DIR=$CWD/out/$PROG

create_dirs "$ERR_DIR" "$OUT_DIR" "$FASTA_DIR"

cd $FASTQ_DIR

i=0
for FILE in *.fastq; do
    i=$((i+1))

    BASENAME=`basename $FILE`

    export IN_FILE="$FASTQ_DIR/$BASENAME"
    #export OUT_FILE=`echo "$FASTA_DIR/$BASENAME" | sed "s/fastq$/fasta/"`

    JOB_ID=`qsub -v SCRIPT_DIR,IN_FILE,FASTA_DIR -N qc_fastq -e "$ERR_DIR/$FILE" -o "$OUT_DIR/$FILE" $SCRIPT_DIR/run_qc.sh`

    printf '%5d: %15s %-30s\n' $i $JOB_ID $BASENAME
    break
done
