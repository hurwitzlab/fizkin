#!/bin/bash

# --------------------------------------------------
#
# 02-screen-host.sh
# 
# Run Jellyfish query for every read against every index
#
# --------------------------------------------------

set -u
source ./config.sh
export INPUT_DIR="$FASTA_DIR"
export STEP_SIZE=1

# --------------------------------------------------

CWD=$PWD
PROG=$(basename $0 ".sh")
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$STDOUT_DIR" 

if [[ ! -d "$SCREENED_DIR" ]]; then
  mkdir -p "$SCREENED_DIR"
fi

if [[ ! -d "$KMER_DIR" ]]; then
  mkdir -p "$KMER_DIR"
fi

if [[ ! -d "$REJECTED_DIR" ]]; then
  mkdir -p "$REJECTED_DIR"
fi

#
# Find input FASTA files
#
export FILES_LIST="${HOME}/${PROG}.in"
find $INPUT_DIR -type f > $FILES_LIST
NUM_FILES=$(lc $FILES_LIST)

echo Found \"$NUM_FILES\" FASTA files in \"$INPUT_DIR\"

if [ $NUM_FILES -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

JOB=$(qsub -N "host-jf" -J 1-$NUM_FILES:$STEP_SIZE -j oe -o "$STDOUT_DIR" -v 
FILES_LIST,DATA_DIR,SCRIPT_DIR,HOST_JELLYFISH_DIR,SCREENED_DIR,KMER_DIR,REJECTED_DIR,MER_SIZE,JELLYFISH,STEP_SIZE $SCRIPT_DIR/screen-host.sh)

if [ $? -eq 0 ]; then
  echo Submitted job \"$JOB\" for you. Sayonara.
else
  echo -e "\nError submitting job\n$JOB\n"
fi
