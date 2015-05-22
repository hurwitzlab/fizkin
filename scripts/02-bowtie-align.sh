#!/bin/bash

# --------------------------------------------------
#
# 02-bowtie-align.sh
# 
# Try to align reads to host genomes using Bowtie2
#
# --------------------------------------------------

set -u
source ./config.sh
export INPUT_DIR="$FASTA_DIR"
export STEP_SIZE=50

# --------------------------------------------------

CWD=$PWD
PROG=$(basename $0 ".sh")
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$STDOUT_DIR" 

#
# This is where the alignments will go
#
if [[ ! -d "$BT_ALIGNED_DIR" ]]; then
  mkdir -p "$BT_ALIGNED_DIR"
fi

#
# Find Bowtie indexes
#
TMP_BT_FILES=$(mktemp)
find $HOST_BOWTIE_DIR -type f | sed "s/\.[0-9]\.bt2$//" | sed "s/\.rev$//" \
  | sort | uniq > $TMP_BT_FILES

#
# Find input FASTA files
#
TMP_FASTA_FILES=$(mktemp)
find $INPUT_DIR -type f > $TMP_FASTA_FILES

export FILES_LIST="${HOME}/${PROG}.in"
if [ -e $FILES_LIST ]; then
  rm -f $FILES_LIST
fi

while read BT_FILE; do
  while read FASTA_FILE; do
    echo "$BT_FILE $FASTA_FILE" >> $FILES_LIST
  done < $TMP_FASTA_FILES
done < $TMP_BT_FILES

NUM_FILES=$(lc $FILES_LIST)

echo Found \"$NUM_FILES\" Bowtie/FASTA pairs in \"$INPUT_DIR\"

if [ $NUM_FILES -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

JOB=$(qsub -N "bt-algn" -J 1-$NUM_FILES:$STEP_SIZE -j oe -o "$STDOUT_DIR" -v SCRIPT_DIR,STEP_SIZE,FILES_LIST,BT_ALIGNED_DIR $SCRIPT_DIR/bowtie-align.sh)

if [ $? -eq 0 ]; then
  echo Submitted job \"$JOB\" for you. Sayonara.
else
  echo -e "\nError submitting job\n$JOB\n"
fi
