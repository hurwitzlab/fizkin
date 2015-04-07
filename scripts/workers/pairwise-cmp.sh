#!/bin/bash

# self-pairwise.cmp.sh

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00
#PBS -m ae
#PBS -M kyclark@email.arizona.edu

set -u

echo Started $(date)

echo Host $(hostname)

PAIRS_FILE=$(mktemp)

if [ -n "$PBS_ARRAY_INDEX" ]; then
    echo PBS_ARRAY_INDEX $PBS_ARRAY_INDEX
    echo STEP_SIZE $STEP_SIZE
    echo FILES_LIST $FILES_LIST

    HEAD=$((${PBS_ARRAY_INDEX:=1} + ${STEP_SIZE:=1}))

    if [ $HEAD -lt 1 ]; then
        echo Cannot figure a HEAD count from PBS_ARRAY_INDEX \"$PBS_ARRAY_INDEX\" and STEP_SIZE \"$STEP_SIZE\"
        exit 1
    fi

    head -n $HEAD $FILES_LIST | tail -n ${STEP_SIZE:=1} > $PAIRS_FILE
elif [ -n "$FASTA" ] && [ -n "$SUFFIX" ]; then
    echo "$FASTA $SUFFIX" > $PAIRS_FILE
fi

NUM_PAIRS=$(wc -l $PAIRS_FILE | cut -d ' ' -f 1)
echo Found \"$NUM_PAIRS\" pairs to process

if [ $NUM_PAIRS -lt 1 ]; then
    echo Nothing to do
    exit 1
fi

if [ -z "$MODE_DIR" ]; then
    echo No MODE_DIR defined
    exit 1
fi

if [ -z "$KMER_DIR" ]; then
    echo No KMER_DIR defined
    exit 1
fi

if [[ ! -x "$JELLYFISH" ]]; then
    echo Cannot find executable jellyfish
    exit 1
fi

i=0
while read FASTA SUFFIX; do
  let i++
  printf "%5d: Processing FASTA \"%s\" to SUFFIX \"%s\"\n" \
    $i $(basename $FASTA) $(basename $SUFFIX)

  BASENAME=$(basename $FASTA ".screened")
  KMER_FILE="$KMER_DIR/${BASENAME}.kmers"
  LOC_FILE="$KMER_DIR/${BASENAME}.loc"
  MODE_OUT_DIR="$MODE_DIR/$BASENAME"

  if [[ ! -e $KMER_FILE ]]; then
      echo Cannot find expected K-mer file \"$KMER_FILE\"
      exit 1
  fi

  if [[ ! -e $LOC_FILE ]]; then
      echo Cannot find expected K-mer location file \"$LOC_FILE\"
      exit 1
  fi

  SUFFIX_BASE=$(basename "$SUFFIX" ".jf")
  OUT_FILE="$MODE_OUT_DIR/$SUFFIX_BASE"

  $JELLYFISH query -i "$SUFFIX" < "$KMER_FILE" | \
    jellyfish-reduce.pl -l "$LOC_FILE" -o "$OUT_FILE" \
    --mode-min 1
done < $PAIRS_FILE

echo Finished $(date)
