#!/bin/bash

# self-pairwise.cmp.sh

#PBS -W group_list=b5mbsaaa
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

set -ux

echo Started $(date)

echo Host $(hostname)

PAIRS_FILE=$(mktemp)

echo PBS_ARRAY_INDEX $PBS_ARRAY_INDEX
echo STEP_SIZE $STEP_SIZE
echo FILES_LIST $FILES_LIST

HEAD=$((${PBS_ARRAY_INDEX:=1} + ${STEP_SIZE:=1}))
echo HEAD $HEAD

if [ $HEAD -lt 1 ]; then
    echo Cannot figure a HEAD count from PBS_ARRAY_INDEX \"$PBS_ARRAY_INDEX\" and STEP_SIZE \"$STEP_SIZE\"
    exit 1
fi

head -n $HEAD $FILES_LIST | tail -n ${STEP_SIZE:=1} > $PAIRS_FILE

echo PAIRS_FILE $PAIRS_FILE
cat $PAIRS_FILE

NUM_PAIRS=$(wc -l $PAIRS_FILE | cut -d ' ' -f 1)

if [ $NUM_PAIRS -lt 1 ]; then
    echo Cannot determine PAIRS from files list \"$FILES_LIST\"
    exit 1
fi

echo Found \"$NUM_PAIRS\" pairs to process

i=0
while read FASTA SUFFIX; do
    let i++
    printf "%5d: Processing FASTA \"%s\" to SUFFIX \"%s\"\n" \
      $i $(basename $FASTA) $(basename $SUFFIX)

    BASENAME=$(basename $FASTA ".screened")
    KMER_FILE="$KMER_DIR/${BASENAME}.kmers"
    LOC_FILE="$KMER_DIR/${BASENAME}.loc"
    DIR="$OUT_DIR/$BASENAME"

    if [[ ! -e $KMER_FILE ]]; then
        echo Cannot find expected K-mer file \"$KMER_FILE\"
        exit 1
    fi

    if [[ ! -e $LOC_FILE ]]; then
        echo Cannot find expected K-mer location file \"$LOC_FILE\"
        exit 1
    fi

    SUFFIX_BASE=$(basename "$SUFFIX" ".jf")
    OUT_FILE="$DIR/$SUFFIX_BASE"

    $JELLYFISH query -i "$SUFFIX" < "$KMER_FILE" | \
      "$SCRIPT_DIR/jellyfish-reduce.pl" -l "$LOC_FILE" -o "$OUT_FILE" \
      --mode-min 1
done < $PAIRS_FILE

echo Finished $(date)

#
# Find all the suffix arrays we'll be using, die if none found
#
#SUFFIX_LIST="$TMPDIR/suffixes"
#
#find $SUFFIX_DIR -name \*.jf > $SUFFIX_LIST
#
#NUM_SUFFIXES=$(wc -l $SUFFIX_LIST | cut -d ' ' -f 1)
#
#if [ $NUM_SUFFIXES -lt 1 ]; then
#    echo Found no Jellyfish indexes in \"$SUFFIX_DIR\"
#    exit 1
#fi

#
# If necessary, kmerize the screened FASTA file
#
#BASENAME=$(basename $FILE ".screened")
#KMER_FILE="$KMER_DIR/${BASENAME}.kmers"
#LOC_FILE="$KMER_DIR/${BASENAME}.loc"
#DIR="$OUT_DIR/$BASENAME"
#
#echo Out dir \"$DIR\"
#
#if [ -d "$DIR" ]; then
#    rm -rf $DIR/*
#else
#    mkdir -p "$DIR"
#fi
#
##echo Kmerizing input FASTA
##$SCRIPT_DIR/kmerizer.pl -q -i "$FILE" -o "$KMER_FILE" \
##  -l "$LOC_FILE" -k "$MER_SIZE" 
#
#if [[ ! -e $KMER_FILE ]]; then
#    echo Cannot find expected K-mer file \"$KMER_FILE\"
#    exit 1
#fi
#
##
## Use our screened FASTA kmer file with each Jellyfish index
##
#i=0
#while read SUFFIX_FILE; do
#    SUFFIX_BASE=$(basename "$SUFFIX_FILE" ".jf")
#    OUT_FILE="$DIR/$SUFFIX_BASE"
#
#    let i++
#    printf "%5d: Processing %s\n" $i $SUFFIX_BASE 
#
#    $JELLYFISH query -i "$SUFFIX_FILE" < "$KMER_FILE" | \
#      "$SCRIPT_DIR/jellyfish-reduce.pl" -l "$LOC_FILE" -o "$OUT_FILE" \
#      --mode-min 1
#done < "$SUFFIX_LIST"
#
#echo Finished $(date)
