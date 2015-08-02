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
export STEP_SIZE=32 # must be a mutliple of 4
export SOURCE_DIR=/rsgrps/bhurwitz/kyclark/mouse/data/host-sorted
export OUT_DIR=/rsgrps/bhurwitz/kyclark/mouse/data/host-jellyfish
export KMERIZE_FILES=0

# --------------------------------------------------

PROG=$(basename "$0" ".sh")
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$STDOUT_DIR"

export FILES_LIST="$HOME/${PROG}.in"

if [ -e $FILES_LIST ]; then
  rm -f $FILES_LIST
fi

if [[ ! -d $OUT_DIR ]]; then
  mkdir -p $OUT_DIR
fi

INPUT_FILES_LIST=${1:-''}
if [ -n "$INPUT_FILES_LIST" ] && [ -e "$INPUT_FILES_LIST" ]; then
  echo Taking files from \"$INPUT_FILES_LIST\"

  while read FILE; do
    if [ -e $FILE ]; then
      echo $FILE >> $FILES_LIST
    else
      echo Bad input file \"$FILE\"
    fi
  done < $INPUT_FILES_LIST
else
  echo "Source dir(s)"
  echo $SOURCE_DIR | sed "s/ /\n/g" | cat -n

  find $SOURCE_DIR -type f | sort > $FILES_LIST
fi

COUNT=$(lc $FILES_LIST)

echo Found \"$COUNT\" files

if [ $COUNT -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

JOBS_ARG=""
if [ $COUNT -gt 1 ]; then
  JOBS_ARG="-J 1-$COUNT"

  if [ $STEP_SIZE -gt 1 ]; then
    JOBS_ARG="$JOBS_ARG:$STEP_SIZE"
  fi
fi

EMAIL_ARG=""
if [[ ! -z $EMAIL ]]; then
  EMAIL_ARG="-M $EMAIL -m ea"
fi

GROUP_ARG="-W group_list=${GROUP:=bhurwitz}"

JOB=$(qsub -N jf_host $GROUP_ARG $JOBS_ARG $EMAIL_ARG -j oe -o "$STDOUT_DIR" -v SCRIPT_DIR,BIN_DIR,STEP_SIZE,MER_SIZE,FILES_LIST,JELLYFISH,OUT_DIR,KMER_DIR,FASTA_SPLIT_DIR,KMERIZE_FILES $SCRIPT_DIR/jellyfish-count-blended.sh)

if [ $? -eq 0 ]; then
  echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" Aloha.
else
  echo -e "\nError submitting job\n$JOB\n"
fi
