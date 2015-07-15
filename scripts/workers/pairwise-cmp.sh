#!/bin/bash

# self-pairwise.cmp.sh

#PBS -q standard
#PBS -l jobtype=cluster_only
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

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

echo MODE_DIR \"$MODE_DIR\"

PAIRS_FILE=$(mktemp)

get_lines $FILES_LIST $PAIRS_FILE ${PBS_ARRAY_INDEX:=1} $STEP_SIZE

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

  FASTA_BASE=$(basename $FASTA ".screened")
  KMER_FILE="$KMER_DIR/${FASTA_BASE}.kmers"
  LOC_FILE="$KMER_DIR/${FASTA_BASE}.loc"
  SUFFIX_BASE=$(basename "$SUFFIX" ".jf")
  MODE_OUT_DIR="$MODE_DIR/$SUFFIX_BASE"
  OUT_FILE="$MODE_OUT_DIR/$FASTA_BASE"

  if [[ ! -d $MODE_OUT_DIR ]]; then
    mkdir -p $MODE_OUT_DIR
  fi

  if [[ ! -e $KMER_FILE ]]; then
      echo Cannot find expected K-mer file \"$KMER_FILE\"
      exit 1
  fi

  if [[ ! -e $LOC_FILE ]]; then
      echo Cannot find expected K-mer location file \"$LOC_FILE\"
      exit 1
  fi

  READ_FILE_ARG=""
  if [[ ! -z $READ_MODE_DIR ]]; then
    READ_MODE_DIR_OUT="$READ_MODE_DIR/$SUFFIX_BASE"

    if [[ ! -d $READ_MODE_DIR_OUT ]]; then
      mkdir -p $READ_MODE_DIR_OUT
    fi

    READ_FILE_ARG="-r $READ_MODE_DIR_OUT/$FASTA_BASE"
  fi

  $JELLYFISH query -i "$SUFFIX" < "$KMER_FILE" | \
    "$SCRIPT_DIR/jellyfish-reduce.pl" -l "$LOC_FILE" -o "$OUT_FILE" \
    $READ_FILE_ARG --mode-min 1
  break
done < $PAIRS_FILE

echo Finished $(date)
