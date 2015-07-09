#!/bin/bash

# --------------------------------------------------
#
# 03-jellyfish-count-screened.sh
#
# Index host-screened FASTA for pairwise analysis
#
# --------------------------------------------------

#set -u
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

if [ -n "$1" ] && [ -e "$1" ]; then
  echo Taking files from \"$1\"
  cp $1 $FILES_LIST
else
  echo Taking files from \"$SOURCE_DIR\"
  find $SOURCE_DIR -name \*.fa > $FILES_LIST
fi

NUM_FILES=$(lc $FILES_LIST)

echo Found \"$NUM_FILES\"

if [ $NUM_FILES -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

JOBS_ARG=""
if [ $NUM_FILES -gt 1 ]; then
  JOBS_ARG="-J 1-$NUM_FILES:$STEP_SIZE "
fi

JOB=$(qsub -N scrn-ct $JOBS_ARG -j oe -o "$STDOUT_DIR" -v SCRIPT_DIR,SOURCE_DIR,MER_SIZE,FILES_LIST,STEP_SIZE,JELLYFISH,KMER_DIR,OUT_DIR $SCRIPT_DIR/jellyfish-count.sh)

# ($?) Expands to the exit status of the most recently executed foreground pipeline.
# And an exit status of 0 (for a 'qsub' command) means no errors
if [ $? -eq 0 ]; then
  echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" Pinne kanam.
else
  echo -e "\nError submitting job\n$JOB\n"
fi
