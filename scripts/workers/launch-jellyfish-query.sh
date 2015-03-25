#!/bin/bash

# launch-jellyfish-query.sh

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=2:mem=10gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00
#PBS -M kyclark@email.arizona.edu

# Expects:
# FASTA_DIR SCRIPT_DIR, SUFFIX_DIR, COUNT_DIR, KMER_DIR, 
# MER_SIZE, JELLYFISH, FILES_LIST

source /usr/share/Modules/init/bash

echo Started `date`

echo Host `hostname`

if [[ ! -d "$FASTA_DIR" ]]; then
    echo Cannot find FASTA dir \"$FASTA_DIR\"
fi

#
# Find out what our input FASTA file is
#
if [[ ! -e $FILES_LIST ]]; then
    echo Cannot find files list \"$FILES_LIST\"
    exit 1
fi

FILE=`head -n +${PBS_ARRAY_INDEX} $FILES_LIST | tail -n 1`

if [ "${FILE}x" == "x" ]; then
    echo Could not get a FASTA file name from \"$FILES_LIST\"
    exit 1
fi

FASTA=`readlink -f "$FASTA_DIR/$FILE"`

echo FASTA file \"$FASTA\"

#
# Find our target Jellyfish files
#
SUFFIX_LIST="$TMPDIR/suffixes"
find $SUFFIX_DIR -name \*.jf > $SUFFIX_LIST
NUM_SUFFIXES=`wc -l $SUFFIX_LIST | cut -d ' ' -f 1`

echo Found $NUM_SUFFIXES suffixes in \"$SUFFIX_DIR\"

if [ $NUM_SUFFIXES -lt 1 ]; then
    echo Cannot find any Jellyfish indexes!
    exit 1
fi

cd $FASTA_DIR

FASTA_BASE=`basename $FASTA`
KMER_FILE="$KMER_DIR/${FASTA_BASE}.kmers"
LOC_FILE="$KMER_DIR/${FASTA_BASE}.loc"

echo Kmerizing

$SCRIPT_DIR/kmerizer.pl -i "$FASTA" -o "$KMER_FILE" \
  -l "$LOC_FILE" -k "$MER_SIZE" 

if [[ ! -e $KMER_FILE ]]; then
    echo Cannot file K-mer file \"$KMER_FILE\"
    exit 1
fi

HOST="$TMPDIR/host"
touch $HOST
echo HOST $HOST

i=0
while read SUFFIX_FILE; do
    let i++
    printf "%5d: Processing %s" $i $SUFFIX_BASE

    #
    # Note: no "-o" output file as we only care about the $HOST file
    #
    $JELLYFISH query -i "$SUFFIX_FILE" < "$KMER_FILE" | \
      "$SCRIPT_DIR/jellyfish-reduce.pl" -l "$LOC_FILE" -u $HOST

    echo Wrote \"$OUT_FILE\"
done < "$SUFFIX_LIST"

echo Done processed $i suffix files

$SCRIPT_DIR/screen-host.pl -h "$HOST" -o "$SCREENED_DIR" $FASTA

rm "$SUFFIX_LIST"
rm "$HOST"

echo Ended `date`
