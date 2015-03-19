#!/bin/bash

# This script runs illumina QC on a directory
# of fastq files, runs the paired read analysis,
# then creates fasta/qual files from the paired
# fastq files

source ./config.sh

export CWD="$PWD"

PROG=`basename $0 ".sh"`
ERR_DIR="$CWD/err/$PROG"
OUT_DIR="$CWD/out/$PROG"

init_dirs "$ERR_DIR" "$OUT_DIR" "$FASTQ_DIR" "$FASTA_DIR"

#
# QC the fastq files 
# For example:
# paired reads are in separate files:
# RNA_1_ACAGTG_L008_R1_001.fastq
# RNA_1_ACAGTG_L008_R2_001.fastq
#

if [[ ! -d $RAW_DIR ]]; then
    echo "Bad RAW_DIR ($RAW_DIR)"
    exit 0
fi

echo "Working in RAW_DIR ($RAW_DIR)"
cd $RAW_DIR
NUM_GZIP=`find $RAW_DIR -name \*gz | wc -l`
if [ $NUM_GZIP -gt 0 ]; then
    echo Gunzipping $NUM_GZIP files
    $GUNZIP *.gz
fi

# send the R1 file and use the name to get the R2 file
i=0
for file in *_R1_*.fastq; do
    i=$((i+1))

    export FILE=`basename $file`

    JOB=`qsub -v SCRIPT_DIR,RAW_DIR,BIN_DIR,FILE,FASTQ_DIR,FASTA_DIR -N qc_fastq -e $ERR_DIR/$FILE -o $OUT_DIR/$FILE $SCRIPT_DIR/qc_fastq.sh`

    printf '%5d: %15s %-30s\n' $i $JOB $FILE
done

echo Submitted $i jobs.  Buenos dias!
