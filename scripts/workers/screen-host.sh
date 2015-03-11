#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=2:mem=10gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00
#PBS -u kyclark@email.arizona.edu

# Expects:
# FASTA_DIR, SCRIPT_DIR, HOST_HITS, SCREENED_DIR, FILES_LIST 

source /usr/share/Modules/init/bash

module load perl

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

echo Screening FASTA file \"$FASTA\" against \"$HOST_HITS\"

$SCRIPT_DIR/screen-host.pl -h "$HOST_HITS" -o "$SCREENED_DIR" $FASTA

echo Ended `date`
