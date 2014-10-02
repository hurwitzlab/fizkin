#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=12:mem=10gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

source /usr/share/Modules/init/bash

for TYR in `cat $INDEX_LIST`; do
    SAMPLE_FASTA_NAME=`basename $TYR | sed "s/\.fa.*//"`
    $GT tallymer search -tyr $TYR -strand fp -output qseqnum qpos counts -q $CWD/$READ > $DEST_DIR/$SAMPLE_FASTA_NAME.count
done

#
# Removed empty (zero-length) files
#
find $DEST_DIR -size 0 -exec rm -f {} \;

