#!/bin/bash

#PBS -W group_list=gwatts
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00
#PBS -M kyclark@email.arizona.edu
#PBS -m ea

# Expects: SOURCE_DIR, MER_SIZE, FILES_LIST, JELLYFISH, OUT_DIR 

set -u

echo Started $(date)

echo Host $(hostname)

source /usr/share/Modules/init/bash

if [ -z $SCRIPT_DIR ]; then
  echo Missing SCRIPT_DIR
  exit 1
fi

KMERIZER="$SCRIPT_DIR/kmerizer.pl"
if [[ ! -e $KMERIZER ]]; then
  echo Cannot find kmerizer \"$KMERIZER\"
  exit 1
fi

THREADS=4
HASH_SIZE="100M"
TMP_FILES=$(mktemp)
HEAD=$((${PBS_ARRAY_INDEX:=1} + ${STEP_SIZE:=1}))

head -n $HEAD $FILES_LIST | tail -n ${STEP_SIZE:=1} > $TMP_FILES

NUM_FILES=$(wc -l $TMP_FILES | cut -d ' ' -f 1)

echo Found \"$NUM_FILES\" files to process

cd "$SOURCE_DIR"

i=0
while read FILE; do
  BASENAME=$(basename $FILE)
  JF_FILE="$OUT_DIR/${BASENAME}.jf"

  let i++
  printf "%5d: %s\n" $i $BASENAME

  if [ -e "$JF_FILE" ]; then
    rm -f "$JF_FILE";
  fi

  $JELLYFISH count -m $MER_SIZE -s $HASH_SIZE -t $THREADS -o $JF_FILE $FILE

  BASENAME=$(basename $FILE)
  KMER_FILE="$KMER_DIR/${BASENAME}.kmers"
  LOC_FILE="$KMER_DIR/${BASENAME}.loc"

  $KMERIZER -q -i "$FILE" -o "$KMER_FILE" -l "$LOC_FILE" -k "$MER_SIZE"
done < $TMP_FILES

echo Finished $(date)
