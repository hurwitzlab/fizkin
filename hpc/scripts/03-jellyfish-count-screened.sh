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

init_dir "$STDOUT_DIR"

if [[  ! -d $KMER_DIR ]]; then
  mkdir -p $KMER_DIR
fi

if [[  ! -d $OUT_DIR ]]; then
  mkdir -p $OUT_DIR
fi

export FILES_LIST="$HOME/$$.in"

if [[ -e $FILES_LIST ]]; then
  rm $FILES_LIST
fi

INPUT_FILES_LIST=${1:-''}
if [[ -n "$INPUT_FILES_LIST" ]] && [[ -e "$INPUT_FILES_LIST" ]]; then
  echo Taking files from \"$INPUT_FILES_LIST\"

  while read FILE; do
    if [[ -e $FILE ]]; then
      echo $FILE >> $FILES_LIST
    else
      echo Bad input file \"$FILE\"
    fi
  done < $INPUT_FILES_LIST
else
  echo Taking files from \"$SOURCE_DIR\"
  find -L $SOURCE_DIR -name \*.fa > $FILES_LIST
fi

NUM_FILES=$(lc $FILES_LIST)

echo Found \"$NUM_FILES\" files
if [[ $NUM_FILES -lt 1 ]]; then
  echo Nothing to do.
  exit 1
fi

JOBS_ARG=""
if [[ $NUM_FILES -gt 1 ]]; then
  JOBS_ARG="-J 1-$NUM_FILES:$STEP_SIZE "
fi

EMAIL_ARG=""
if [[ ! -z $EMAIL ]]; then
  EMAIL_ARG="-M $EMAIL -m ea"
fi

GROUP_ARG="-W group_list=${GROUP:=bhurwitz}"

JOB=$(qsub -N scrn-ct $JOBS_ARG $EMAIL_ARG $GROUP_ARG -j oe -o "$STDOUT_DIR" -v SCRIPT_DIR,SOURCE_DIR,MER_SIZE,FILES_LIST,STEP_SIZE,JELLYFISH,KMER_DIR,OUT_DIR,FASTA_SPLIT_DIR,MAX_JELLYFISH_INPUT_SIZE $SCRIPT_DIR/jellyfish-count.sh)

if [[ $? -eq 0 ]]; then
  echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" Pinne kanam.
else
  echo -e "\nError submitting job\n$JOB\n"
fi
