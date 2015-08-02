#!/bin/bash


#PBS -q standard
#PBS -l jobtype=cluster_only
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l pvmem=20gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

source /usr/share/Modules/init/bash

set -u

COMMON="$SCRIPT_DIR/common.sh"

if [ -e $COMMON ]; then
  . "$COMMON"
else
  echo Missing common \"$COMMON\"
  exit 1
fi

if [ -z $SCRIPT_DIR ]; then
  echo Missing SCRIPT_DIR
  exit 1
fi

FASTAR=$BIN_DIR/fastar 

if [[ ! -e $FASTAR ]]; then
  echo Cannot find FASTAR \"$FASTAR\"
  exit 1
fi

THREADS=4
HASH_SIZE="100M"
TMP_FILES=$(mktemp)
get_lines $FILES_LIST $TMP_FILES ${PBS_ARRAY_INDEX:=1} $STEP_SIZE

NUM_FILES=$(lc $TMP_FILES)

echo Processing \"$NUM_FILES\" input files into OUT_DIR \"$OUT_DIR\"

i=0
while FASTA_FILES=$(readlines 4); do
  FIRST=$(echo $FASTA_FILES | awk '{print $1}')
  BASENAME=$(basename $FIRST)
  JF_FILE="$OUT_DIR/${BASENAME}.jf"

  let i++
  printf "%5d: %s\n" $i "$JF_FILE"

  if [[ ! -e $JF_FILE ]]; then
    TMP_FASTA=$(mktemp --tmpdir=$OUT_DIR "$$.XXXXXXXX")
    cat $FASTA_FILES | $FASTAR > $TMP_FASTA
    $JELLYFISH count -m $MER_SIZE -s $HASH_SIZE -t $THREADS -o $JF_FILE $TMP_FASTA
    rm $TMP_FASTA
  fi
done < $TMP_FILES

echo Done.
