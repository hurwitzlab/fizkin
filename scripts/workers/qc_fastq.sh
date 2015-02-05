#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=2:mem=5gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

# expects: 
# SCRIPT_DIR RAW_DIR BIN_DIR FILE FASTQ_DIR FASTA_DIR 

# R is needed by the SolexaQA++ program
hostname 

module load R

source /usr/share/Modules/init/bash

SED=/bin/sed

cd $RAW_DIR

#
# The following script runs QC on  
# a set of paired end illumina fastq
# files
#

FILES=($FILE)
TRIMMED=(${FILE}.trimmed)
FILE2=$(echo $FILE | $SED 's/_R1_/_R2_/')

if [ -e $FILE2 ]; then
    FILES+=" $FILE2"
    TRIMMED+=" ${FILE2}.trimmed"
fi

$BIN_DIR/SolexaQA++ analysis -d $FASTQ_DIR ${FILES[@]}
$BIN_DIR/SolexaQA++ dynamictrim -d $FASTQ_DIR ${FILES[@]}

cd $FASTQ_DIR

$BIN_DIR/SolexaQA++ lengthsort -d $FASTQ_DIR ${TRIMMED[@]}

#
# create a fasta file from fastq
#
for f in ${TRIMMED[@]}; do
    BASE=`basename $f '.trimmed' | sed "s/fastq/fa/"`
    $SCRIPT_DIR/fastq2fasta.awk $f > $FASTA_DIR/$BASE
done
