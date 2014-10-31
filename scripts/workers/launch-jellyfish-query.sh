#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q windfall
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=12:mem=10gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

source /usr/share/Modules/init/bash

$SCRIPT_DIR/jellyfish-query.pl -s "$SUFFIX" -o "$COUNT_DIR" -k "$MER_SIZE" -j "$JELLYFISH" $KMER_DIR/*.kmers


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
