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
export STEP_SIZE=30
export SOURCE_DIR="$HOST_DIR"
export OUT_DIR=$HOST_JELLYFISH_DIR
export KMERIZE_FILES=0

# --------------------------------------------------

PROG=$(basename "$0" ".sh")
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$STDOUT_DIR"
init_dirs "$OUT_DIR"

export FILES_LIST="$HOME/${PROG}.in"

if [ -e $FILES_LIST ]; then
  rm -f $FILES_LIST
fi

i=0
for SRC_DIR in $SOURCE_DIR; do
  let i++

  printf "%5d: %s\n" $i $SRC_DIR

  find $SRC_DIR -type f >> $FILES_LIST
done

COUNT=$(lc $FILES_LIST)

echo Found \"$COUNT\" files

if [ $COUNT -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

JOBS_ARG=""
if [ $COUNT -gt 1 ]; then
  JOBS_ARG="-J 1-$COUNT:$STEP_SIZE "
fi

EMAIL_ARG=""
if [[ ! -z $EMAIL ]]; then
  EMAIL_ARG="-M $EMAIL -m ea"
fi

GROUP_ARG="-W group_list=${GROUP:=bhurwitz}"

export MAX_JELLYFISH_INPUT_SIZE=200
JOB=$(qsub -N jf_host $GROUP_ARG $JOBS_ARG $EMAIL_ARG -j oe -o "$STDOUT_DIR" -v SCRIPT_DIR,STEP_SIZE,MER_SIZE,FILES_LIST,JELLYFISH,OUT_DIR,KMER_DIR,FASTA_SPLIT_DIR,MAX_JELLYFISH_INPUT_SIZE,KMERIZE_FILES $SCRIPT_DIR/jellyfish-count.sh)

if [ $? -eq 0 ]; then
  echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" Aloha.
else
  echo -e "\nError submitting job\n$JOB\n"
fi
