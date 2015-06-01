#!/bin/bash

#PBS -W group_list=mbsulli
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00
#PBS -M kyclark@email.arizona.edu
#PBS -m ea

# Expects: STEP_SIZE
# SCRIPT_DIR STEP_SIZE MER_SIZE FILES_LIST JELLYFISH OUT_DIR FASTA_SPLIT_DIR
# KMERIZE_FILES KMER_DIR

source /usr/share/Modules/init/bash

set -u

COMMON="$SCRIPT_DIR/common.sh"

if [ -e $COMMON ]; then
  . "$COMMON"
else
  echo Missing common \"$COMMON\"
  exit 1
fi

echo Started $(date)

echo Host $(hostname)

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

get_lines $FILES_LIST $TMP_FILES ${PBS_ARRAY_INDEX:=1} $STEP_SIZE

NUM_FILES=$(lc $TMP_FILES)

echo Processing \"$NUM_FILES\" input files

#
# Need to make sure none of these files are too large
#
TMP_CHECKED=$(mktemp)
MAX_MB=200 
while read FILE; do
  SIZE=$(du -m "$FILE" | cut -f 1)

  if [ $SIZE -ge $MAX_MB ]; then
    echo Splitting $(basename $FILE)
    $SCRIPT_DIR/fasta-split.pl -m $MAX_MB -f $FILE -o $FASTA_SPLIT_DIR

    BASENAME=$(basename $FILE)
    BASENAME=${BASENAME%.*}
    find $FASTA_SPLIT_DIR -name $BASENAME\* -type f >> $TMP_CHECKED
  else
    echo $FILE >> $TMP_CHECKED
  fi
done < $TMP_FILES

NUM_FILES=$(lc $TMP_CHECKED)

echo After checking to split, we have \"$NUM_FILES\" files

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

  if [[ ${KMERIZE_FILES:=0} -gt 0 ]]; then
    KMER_FILE="$KMER_DIR/${BASENAME}.kmers"
    LOC_FILE="$KMER_DIR/${BASENAME}.loc"

    $KMERIZER -q -i "$FILE" -o "$KMER_FILE" -l "$LOC_FILE" -k "$MER_SIZE"
  fi
done < $TMP_CHECKED

if [ -d $FASTA_SPLIT_DIR ]; then
  rm -rf $FASTA_SPLIT_DIR
fi

echo Finished $(date)
