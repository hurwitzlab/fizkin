#!/bin/bash

# --------------------------------------------------
#
# 01-jellyfish-count-host.sh
#
# Use Jellyfish to index host FASTA
#
# --------------------------------------------------

set -u
source ./config.sh
export CWD=$PWD
export SOURCE_DIR="$HOST_DIR"
export OUT_DIR="$HOST_JELLYFISH_DIR"

# --------------------------------------------------

PROG=$(basename "$0" ".sh")
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$ERR_DIR" "$OUT_DIR"

export FILES_LIST="$HOME/${PROG}.in"

find $SOURCE_DIR -type f -name \*.fa > $FILES_LIST

COUNT=$(lc $FILES_LIST)

echo Found \"$COUNT\" files in \"$SOURCE_DIR\"

if [ $COUNT -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

JOB=$(qsub -N jf_host -j oe -o "$STDOUT_DIR" -J 1-$COUNT -v SOURCE_DIR,MER_SIZE,FILES_LIST,JELLYFISH,OUT_DIR $SCRIPT_DIR/jellyfish-count.sh)

if [ $? -eq 0 ]; then
  echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" Aloha.
else
  echo -e "\nError submitting job\n$JOB\n"
fi
