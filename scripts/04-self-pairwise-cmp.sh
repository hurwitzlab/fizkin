#!/bin/bash

# --------------------------------------------------
#
# 04-self-pairwise-cmp.sh
#
# Use Jellyfish to run a pairwise comparison of all screened samples
#
# --------------------------------------------------

set -u
source ./config.sh
INPUT_DIR="$FASTA_DIR"
export SUFFIX_DIR="$JELLYFISH_DIR"
export OUT_DIR="$MODE_DIR"
export STEP_SIZE=90

# --------------------------------------------------

CWD=$PWD
PROG=$(basename $0 ".sh")
STDERR_DIR="$CWD/err/$PROG"
STDOUT_DIR="$CWD/out/$PROG"
JOB_INFO_DIR="$CWD/job-info/$PROG"

init_dirs "$STDERR_DIR" "$STDOUT_DIR" "$JOB_INFO_DIR"

if [[ ! -d "$OUT_DIR" ]]; then
    mkdir "$OUT_DIR"
fi

if [[ ! -d "$KMER_DIR" ]]; then
    mkdir "$KMER_DIR"
fi

#
# Find all the input files
#
INPUT_FILES=$(mktemp)

find $INPUT_DIR -name \*.fa > $INPUT_FILES

NUM_INPUT_FILES=$(lc $INPUT_FILES)

echo Found \"$NUM_INPUT_FILES\" files in \"$INPUT_DIR\"

if [ $NUM_INPUT_FILES -lt 1 ]; then
    echo Nothing to do.
    exit 1
fi

#
# Find all the suffix arrays
#
JELLYFISH_FILES=$(mktemp)

find $JELLYFISH_DIR -name \*.jf > $JELLYFISH_FILES

NUM_JF_FILES=$(lc $JELLYFISH_FILES)

echo Found \"$NUM_JF_FILES\" indexes in \"$JELLYFISH_DIR\"

if [ $NUM_JF_FILES -lt 1 ]; then
    echo Nothing to do.
    exit 1
fi

#
# Pair up the FASTA/Jellyfish files
#
export FILES_LIST="${INPUT_DIR}/files-list"
if [ -e $FILES_LIST ]; then
    rm -f $FILES_LIST 
fi

while read FASTA; do
    while read SUFFIX; do
        echo "$FASTA $SUFFIX" >> $FILES_LIST
    done < $JELLYFISH_FILES
done < $INPUT_FILES

NUM_PAIRS=$(lc $FILES_LIST)

if [ $NUM_PAIRS -lt 1 ]; then
    echo Could not generate file pairs
    exit 1
fi

echo There are \"$NUM_PAIRS\" pairs to process 

JOB=$(qsub -N "self-qry" -J 1-$NUM_PAIRS:$STEP_SIZE -e "$STDERR_DIR" -o "$STDOUT_DIR" -v SCRIPT_DIR,SUFFIX_DIR,OUT_DIR,KMER_DIR,MER_SIZE,JELLYFISH,FILES_LIST,STEP_SIZE $SCRIPT_DIR/pairwise-cmp.sh)

if [ $? -eq 0 ]; then
    echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" Sayonara.
else
    echo -e "\nError submitting job\n$JOB\n"
fi

rm $JELLYFISH_FILES
rm $INPUT_FILES
