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
FILE_PATTERN="\*.screened"

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

export FILES_LIST="$SCREENED_DIR/file-list";

cd $SCREENED_DIR

find . -name $FILE_PATTERN | sed "s/^\.\///" > $FILES_LIST

NUM_FILES=`wc -l $FILES_LIST | cut -d ' ' -f 1`

if [ $NUM_FILES -gt 0 ]; then
    echo Processing $NUM_FILES screened FASTA files in \"$SCREENED_DIR\"

    JOB_ID=`qsub -N "query" -J 1-$NUM_FILES -e "$STDERR_DIR" -o "$STDOUT_DIR" -v SCRIPT_DIR,SUFFIX_DIR,OUT_DIR,SCREENED_DIR,KMER_DIR,MER_SIZE,JELLYFISH,FILES_LIST $SCRIPT_DIR/pairwise-cmp.sh`

    echo Submitted \"$JOB_ID\" for you.  Namaste.
else
    echo Could not find any files in \"${FASTA_DIR}.\"
fi
