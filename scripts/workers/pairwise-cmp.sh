#!/bin/bash

# self-pairwise.cmp.sh

#PBS -W group_list=bhurwitz
#PBS -q windfall
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

#set -ux

# MER_SIZE JELLYFISH FILES_LIST 

echo Started $(date)

echo Host $(hostname)

FILE=$(head -n +${PBS_ARRAY_INDEX:=1} $FILES_LIST | tail -n 1)

echo Input FASTA \"$(basename $FILE)\"

#
# Find all the suffix arrays we'll be using, die if none found
#
SUFFIX_LIST="$TMPDIR/suffixes"

find $SUFFIX_DIR -name \*.jf > $SUFFIX_LIST

NUM_SUFFIXES=$(wc -l $SUFFIX_LIST | cut -d ' ' -f 1)

if [ $NUM_SUFFIXES -lt 1 ]; then
    echo Found no Jellyfish indexes in \"$SUFFIX_DIR\"
    exit 1
fi

#
# If necessary, kmerize the screened FASTA file
#
BASENAME=$(basename $FILE ".screened")
KMER_FILE="$KMER_DIR/${BASENAME}.kmers"
LOC_FILE="$KMER_DIR/${BASENAME}.loc"
DIR="$OUT_DIR/$BASENAME"

echo Out dir \"$DIR\"

if [ -d "$DIR" ]; then
    rm -rf $DIR/*
else
    mkdir -p "$DIR"
fi

echo Kmerizing input FASTA
$SCRIPT_DIR/kmerizer.pl -q -i "$FILE" -o "$KMER_FILE" \
  -l "$LOC_FILE" -k "$MER_SIZE" 

if [[ ! -e $KMER_FILE ]]; then
    echo Cannot file K-mer file \"$KMER_FILE\"
    exit 1
fi

#
# Use our screened FASTA kmer file with each Jellyfish index
#
i=0
while read SUFFIX_FILE; do
    SUFFIX_BASE=$(basename "$SUFFIX_FILE" ".jf")
    OUT_FILE="$DIR/$SUFFIX_BASE"

    let i++
    printf "%5d: Processing %s\n" $i $SUFFIX_BASE 

    $JELLYFISH query -i "$SUFFIX_FILE" < "$KMER_FILE" | \
      "$SCRIPT_DIR/jellyfish-reduce.pl" -l "$LOC_FILE" -o "$OUT_FILE" \
      --mode-min 1
done < "$SUFFIX_LIST"

echo Finished $(date)
