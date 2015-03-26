#!/bin/bash

#
# 04-self-pairwise-cmp.sh
#
# Use Jellyfish to run a pairwise comparison of all screened samples
#
# --------------------------------------------------

source ./config.sh
export SUFFIX_DIR="$JELLYFISH_DIR"
export OUT_DIR="$MODE_DIR"

# --------------------------------------------------

CWD=$PWD
PROG=`basename $0 ".sh"`
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

export FILES_LIST="${SCREENED_DIR}/files-list"

find $SCREENED_DIR -name \*.screened | sed "s/^\.\///" > $FILES_LIST

NUM_FILES=`wc -l $FILES_LIST | cut -d ' ' -f 1`

echo Found \"$NUM_FILES\" screened FASTA files in \"$SCREENED_DIR\"

if [ $NUM_FILES -lt 1 ]; then
    echo Nothing to do.
    exit 1
fi

JOB=`qsub -N "self-qry" -J 1-$NUM_FILES -e "$STDERR_DIR" -o "$STDOUT_DIR" -v SCRIPT_DIR,SUFFIX_DIR,OUT_DIR,SCREENED_DIR,KMER_DIR,MER_SIZE,JELLYFISH,FILES_LIST $SCRIPT_DIR/pairwise-cmp.sh`

if [ $? -eq 0 ]; then
    echo Submitted job \"$JOB\" for you. Namaste.
else
    echo -e "\nError submitting job\n$JOB\n"
fi
