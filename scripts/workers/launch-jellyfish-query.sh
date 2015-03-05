#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=1:mem=2gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00
#PBS -M kyclark@email.arizona.edu

# Expects:
# FASTA_DIR SCRIPT_DIR, SUFFIX_DIR, COUNT_DIR, KMER_DIR, 
# MER_SIZE, JELLYFISH, FILE_LIST

echo Started `date`

source /usr/share/Modules/init/bash

if [[ ! -e $FILE_LIST ]]; then
    echo Cannot find file list \"$FILE_LIST\"
    exit 1
fi

FASTA=`head -n +${PBS_ARRAY_INDEX} $FILE_LIST | tail -n 1`

if [ "${FASTA}x" == "x" ]; then
    echo Could not get a FASTA file name from \"$FILE_LIST\"
    exit 1
fi

echo FASTA DIR \"$FASTA_DIR\"
echo FASTA FILE \"$FASTA\"

cd $FASTA_DIR

time $SCRIPT_DIR/kmerizer.pl -k "$MER_SIZE" -o "$KMER_DIR" -v $FASTA

BASENAME=`basename $FASTA`

KMER_FILE="$KMER_DIR/${BASENAME}.kmers"

if [ -e $KMER_FILE ]; then
    time $SCRIPT_DIR/jellyfish-query.pl -v -s "$SUFFIX_DIR" -o "$COUNT_DIR" \
      -k "$MER_SIZE" -j "$JELLYFISH" -q $KMER_FILE
else
    echo Cannot file K-mer file \"$KMER_FILE\"
fi

echo Ended `date`
