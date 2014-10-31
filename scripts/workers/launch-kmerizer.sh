#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q windfall
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=12:mem=10gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

source /usr/share/Modules/init/bash

$SCRIPT_DIR/kmerizer.pl -o $KMER_DIR -k $MER_SIZE $FILE
