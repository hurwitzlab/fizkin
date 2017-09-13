#!/bin/bash
# 00-fastq-to-fasta.sh

set -u

BIN="$( readlink -f -- "$( dirname -- "$0" )" )"
CONFIG=$BIN/config.sh

if [[ -e $CONFIG ]]; then 
  source $CONFIG
else
  echo Missing CONFIG \"$CONFIG\"
  exit
fi

if [[ -z "$FASTQ_DIR" ]]; then
  echo FASTQ_DIR not defined
  exit
fi

if [[ -z "$FASTA_DIR" ]]; then
  echo FASTA_DIR not defined
  exit
fi

if [[ ! -d $FASTQ_DIR ]]; then
  echo Bad FASTQ_DIR \"$FASTQ_DIR\"
  exit
fi

if [[ ! -d $FASTA_DIR ]]; then
  mkdir -p $FASTA_DIR
fi

export CWD="$PWD"
export STEP_SIZE=20

PROG=$(basename $0 ".sh")
PBSOUT_DIR="$BIN/pbs-out/$PROG"

init_dir "$PBSOUT_DIR"

export FILES_LIST="${HOME}/$$.in"

find $FASTQ_DIR -type f > $FILES_LIST

NUM_FILES=$(lc $FILES_LIST)

echo Found \"$NUM_FILES\" input files

if [ $NUM_FILES -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

EMAIL_ARG=""
if [[ ! -z $EMAIL ]]; then
  EMAIL_ARG="-M $EMAIL -m ea"
fi

GROUP_ARG="-W group_list=${GROUP:=bhurwitz}"

JOB=$(qsub -J 1-$NUM_FILES:$STEP_SIZE $EMAIL_ARG $GROUP_ARG -v STEP_SIZE,SCRIPT_DIR,BIN_DIR,FILES_LIST,FASTQ_DIR,FASTA_DIR -N fq2fa -j oe -o "$PBSOUT_DIR" $SCRIPT_DIR/fastq-to-fasta.sh)

if [ $? -eq 0 ]; then
  echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" 
else
  echo -e "\nError submitting job\n$JOB\n"
fi
