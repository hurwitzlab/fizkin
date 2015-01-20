#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=1:mem=2gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00
#PBS -M kyclark@email.arizona.edu

source /usr/share/Modules/init/bash

# SCRIPT_DIR, JELLYFISH_DIR, COUNT_DIR, KMER_DIR, FASTA, MER_SIZE, JELLYFISH

date
echo $SCRIPT_DIR/kmerizer.pl -k "$MER_SIZE" -o "$KMER_DIR" $FASTA
$SCRIPT_DIR/kmerizer.pl -k "$MER_SIZE" -o "$KMER_DIR" $FASTA

echo 
date
BASENAME=`basename $FASTA`

echo $SCRIPT_DIR/jellyfish-query.pl -v -s "$JELLYFISH_DIR" -o "$COUNT_DIR" \
  -k "$MER_SIZE" -j "$JELLYFISH" "$KMER_DIR/${BASENAME}.kmers"

$SCRIPT_DIR/jellyfish-query.pl -s "$JELLYFISH_DIR" -o "$COUNT_DIR" \
  -k "$MER_SIZE" -j "$JELLYFISH" -q "$KMER_DIR/${BASENAME}.kmers"

echo
echo Finished
date

#Usage:
#      jellyfish-query.pl -s /path/to/suffix -o /path/to/output kmer.files ...
#
#      Required Arguments:
#
#        -s|--suffix     The Jellyfish suffix file
#        -o|--out        Directory to write the output
#
#      Options:
#
#        -j|--jellyfish  Path to "jellyfish" binary (default "/usr/local/bin")
#        -k|--kmer       Size of the kmers (default "20")
#        -v|--verbose    Show progress while processing sequences
#        --help          Show brief help and exit
#        --man           Show full documentation
#
