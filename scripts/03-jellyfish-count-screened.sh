#!/bin/bash

# --------------------------------------------------
#
# 03-jellyfish-count-screened.sh
#
# Index host-screened FASTA for pairwise analysis
#
# --------------------------------------------------

set -u
source ./config.sh
export SOURCE_DIR="$SCREENED_DIR"
export OUT_DIR="$JELLYFISH_DIR"
export STEP_SIZE=100
export CWD="$PWD"

# --------------------------------------------------

PROG=$(basename "$0" ".sh")
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$STDOUT_DIR" 

if [[  ! -d $KMER_DIR ]]; then
  mkdir -p $KMER_DIR
fi

if [[  ! -d $OUT_DIR ]]; then
  mkdir -p $OUT_DIR
fi

export FILES_LIST="$HOME/${PROG}.in"

find $SOURCE_DIR -name \*.fa > $FILES_LIST

NUM_FILES=$(lc $FILES_LIST)

echo Found \"$NUM_FILES\" files in \"$SOURCE_DIR\"

if [ $NUM_FILES -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

JOB=$(qsub -N jf_self -J 1-$NUM_FILES:$STEP_SIZE -j oe -o "$STDOUT_DIR" -v SCRIPT_DIR,SOURCE_DIR,MER_SIZE,FILES_LIST,STEP_SIZE,JELLYFISH,KMER_DIR,OUT_DIR $SCRIPT_DIR/jellyfish-count.sh)

if [ $? -eq 0 ]; then
  echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" Pinne kanam.
else
  echo -e "\nError submitting job\n$JOB\n"
fi
