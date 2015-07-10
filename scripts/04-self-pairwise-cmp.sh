#!/bin/bash

# --------------------------------------------------
#
# 04-self-pairwise-cmp.sh
#
# Use Jellyfish to run a pairwise comparison of all screened samples
#
# --------------------------------------------------

set -u
source ./config.sh
INPUT_DIR="$FASTA_DIR"
export SUFFIX_DIR="$JELLYFISH_DIR"
export STEP_SIZE=90

# --------------------------------------------------

CWD=$PWD
PROG=$(basename $0 ".sh")
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$STDOUT_DIR"

if [[ ! -d "$MODE_DIR" ]]; then
  mkdir "$MODE_DIR"
fi

if [[ ! -d "$KMER_DIR" ]]; then
  mkdir "$KMER_DIR"
fi

#
# Find all the input files
#
INPUT_FILES=$(mktemp)

INPUT_FILE_NAME=${1:-''}
if [ -n "$INPUT_FILE_NAME" ] && [ -e "$INPUT_FILE_NAME" ]; then
  echo Taking input files from \"$INPUT_FILE_NAME\"
  cp $INPUT_FILE_NAME $INPUT_FILES
else
  if [[ ! -d "$INPUT_DIR" ]]; then
    echo INPUT_DIR \"$INPUT_DIR\" does not exist
    exit 1
  fi

  echo Seaching for input files in \"$INPUT_DIR\"
  find $INPUT_DIR -type f > $INPUT_FILES
fi

NUM_INPUT_FILES=$(lc $INPUT_FILES)

echo Found \"$NUM_INPUT_FILES\" files in \"$INPUT_DIR\"

if [ $NUM_INPUT_FILES -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

#
# Find all the suffix arrays
#
JELLYFISH_FILES=$(mktemp)

while read FASTA; do
    find $JELLYFISH_DIR -name $(basename $FASTA).jf >> $JELLYFISH_FILES
done < $INPUT_FILES

NUM_JF_FILES=$(lc $JELLYFISH_FILES)

echo Found \"$NUM_JF_FILES\" indexes in \"$JELLYFISH_DIR\"

if [ $NUM_JF_FILES -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

#
# Pair up the FASTA/Jellyfish files
#
if [ $NUM_JF_FILES -ne $NUM_INPUT_FILES ]; then
  echo Different number of Jellyfish/FASTA files, quitting.
  exit 1
fi

export FILES_LIST="${HOME}/$$.in"

if [ -e $FILES_LIST ]; then
  rm -f $FILES_LIST 
fi

while read FASTA; do
  while read SUFFIX; do
    echo "$FASTA $SUFFIX" >> $FILES_LIST
  done < $JELLYFISH_FILES
done < $INPUT_FILES

NUM_PAIRS=$(lc $FILES_LIST)

if [ $NUM_PAIRS -lt 1 ]; then
  echo Could not generate file pairs
  exit 1
fi

echo There are \"$NUM_PAIRS\" pairs to process 

JOB=$(qsub -N "pair-cmp" -J 1-$NUM_PAIRS:$STEP_SIZE -j oe -o "$STDOUT_DIR" -v SCRIPT_DIR,SUFFIX_DIR,MODE_DIR,KMER_DIR,MER_SIZE,JELLYFISH,FILES_LIST,STEP_SIZE $SCRIPT_DIR/pairwise-cmp.sh)

if [ $? -eq 0 ]; then
  echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" Adios.
else
  echo -e "\nError submitting job\n$JOB\n"
fi

rm $JELLYFISH_FILES
