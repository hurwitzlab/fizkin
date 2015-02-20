#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=2:mem=10gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

module load perl

$SCRIPT_DIR/quality-filter-454.pl -f $IN_FILE -o $FASTA_DIR
