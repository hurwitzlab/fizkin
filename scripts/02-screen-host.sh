#!/bin/bash

# --------------------------------------------------
#
# 02-screen-host.sh
# 
# Run Jellyfish query for every read against every index
#
# --------------------------------------------------

source ./config.sh
export SUFFIX_DIR="$HOST_JELLYFISH_DIR"
export INPUT_DIR="$FASTA_DIR"
FILE_PATTERN="DNA\*.fa"

# --------------------------------------------------

CWD=$PWD
PROG=$(basename $0 ".sh")
STDERR_DIR="$CWD/err/$PROG"
STDOUT_DIR="$CWD/out/$PROG"
JOB_INFO_DIR="$CWD/job-info/$PROG"

init_dirs "$STDERR_DIR" "$STDOUT_DIR" "$JOB_INFO_DIR"

if [[ ! -d "$COUNT_DIR" ]]; then
    mkdir "$COUNT_DIR"
fi

if [[ ! -d "$KMER_DIR" ]]; then
    mkdir "$KMER_DIR"
fi

#
# Find input FASTA files
#
FILES_LIST="${INPUT_DIR}/${PROG}.in"
find $INPUT_DIR -name "$FILE_PATTERN" > $FILES_LIST
NUM_FILES=$(lc $FILES_LIST)

echo Found \"$NUM_FILES\" FASTA files in \"$INPUT_DIR\"

if [ $NUM_FILES -lt 1 ]; then
    echo Nothing to do.
    exit 1
fi

export PATH=$SCRIPT_DIR:$PATH

JOB_ID=$(qsub -N "host-jf" -J 1-$NUM_FILES -e "$STDERR_DIR" -o "$STDOUT_DIR" -v FILES_LIST,COUNT_DIR,SCREENED_DIR,KMER_DIR,MER_SIZE,JELLYFISH $SCRIPT_DIR/screen-host.sh)

if [ $? -eq 0 ]; then
    echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" Sayonara.
else
    echo -e "\nError submitting job\n$JOB\n"
fi

rm $INPUT_LIST
rm $SUFFIX_LIST
