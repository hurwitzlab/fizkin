#!/bin/bash

# --------------------------------------------------
# neg1-just-fastqc.sh
#
# This script runs fastqc 0.11.2 on files
#
# --------------------------------------------------

set -u
source ./config.sh
export CWD="$PWD"
export STEP_SIZE=20

PROG=$(basename $0 ".sh")
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$STDOUT_DIR"

if [[ ! -d $RAW_DIR ]]; then
  echo "Bad RAW_DIR ($RAW_DIR)"
  exit 0
fi

if [[ ! -d $FASTQC_REPORTS ]]; then
  mkdir -p $FASTQC_REPORTS
fi

if [[ ! -d $FASTA_DIR ]]; then
  mkdir -p $FASTA_DIR
fi

echo RAW_DIR \"$RAW_DIR\"

export FILES_LIST="$PROJECT_DIR/$$.in"

#
# find those DNA/RNA files!
#
find $RAW_DIR -name DNA\* > $FILES_LIST

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

JOB=$(qsub -J 1-$NUM_FILES:$STEP_SIZE \
    -V \
    -N fastqc \
    -j oe \
    -o "$STDOUT_DIR" \
    $EMAIL_ARG \
    $GROUP_ARG \
    $WORKER_DIR/fastqc.sh)

if [ $? -eq 0 ]; then
  echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" Sayonara.
else
  echo -e "\nError submitting job\n$JOB\n"
fi
