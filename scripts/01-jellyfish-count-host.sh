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
export INPUT_GROUP_FILE=""
export JELLYFISH_OUT_COUNTER_LEN=1

# --------------------------------------------------

PROG=$(basename "$0" ".sh")
PBSOUT_DIR="$CWD/pbs-out/$PROG"

init_dir "$PBSOUT_DIR"

export FILES_LIST="$HOME/$$.in"

if [[ -e $FILES_LIST ]]; then
  rm -f $FILES_LIST
fi

if [[ ! -d $OUT_DIR ]]; then
  mkdir -p $OUT_DIR
fi

INPUT_FILES_LIST=${1:-''}
if [[ -n "$INPUT_FILES_LIST" ]] && [[ -e "$INPUT_FILES_LIST" ]]; then
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

  find $SOURCE_DIR -type f > $FILES_LIST
fi

COUNT=$(lc $FILES_LIST)

echo Found \"$COUNT\" files

if [[ $COUNT -lt 1 ]]; then
  echo Nothing to do.
  exit 1
fi

JOBS_ARG=""
if [[ $COUNT -gt 1 ]]; then
  JOBS_ARG="-J 1-$COUNT"

  if [[ $STEP_SIZE -gt 1 ]]; then
    JOBS_ARG="$JOBS_ARG:$STEP_SIZE"
  fi
fi

DISTRIBUTOR=$SCRIPT_DIR/distributor.pl

if [[ -e $DISTRIBUTOR ]]; then
  echo Working to distribute files -- gimme a sec

  FILE_SIZES=$(mktemp)
  while read FILE; do
    ls -l $FILE | awk '{print $5 " " $9}' >> $FILE_SIZES
  done < $FILES_LIST

  INPUT_GROUP_FILE=$HOME/$PROG.input_groups

  $DISTRIBUTOR $FILE_SIZES > $INPUT_GROUP_FILE

  rm $FILE_SIZES
fi

if [[ ${INPUT_GROUP_FILE:="x"} != "x" ]] && [[ -e $INPUT_GROUP_FILE ]]; then
  LAST_GROUP=$(tail -n 1 $INPUT_GROUP_FILE | cut -f 1)

  JOBS_ARG="-J 1-$LAST_GROUP"
  STEP_SIZE=0

  echo JOBS_ARG \"$JOBS_ARG\"
fi

EMAIL_ARG=""
if [[ ! -z $EMAIL ]]; then
  EMAIL_ARG="-M $EMAIL -m ea"
fi

GROUP_ARG="-W group_list=${GROUP:=bhurwitz}"

JOB=$(qsub -N jf_host $GROUP_ARG $JOBS_ARG $EMAIL_ARG -j oe -o "$PBSOUT_DIR" -v SCRIPT_DIR,STEP_SIZE,MER_SIZE,FILES_LIST,JELLYFISH,OUT_DIR,KMER_DIR,FASTA_SPLIT_DIR,MAX_JELLYFISH_INPUT_SIZE,KMERIZE_FILES,INPUT_GROUP_FILE,JELLYFISH_OUT_COUNTER_LEN $SCRIPT_DIR/jellyfish-count.sh)

if [[ $? -eq 0 ]]; then
  echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" Aloha.
else
  echo -e "\nError submitting job\n$JOB\n"
fi
