#!/bin/bash

#PBS -W group_list=gwatts
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00
#PBS -M kyclark@email.arizona.edu
#PBS -m ea

# --------------------------------------------------
set -u

# R is needed for the "sna.pl" script
module load R

echo Started $(date)

echo Host $(hostname)

source /usr/share/Modules/init/bash

MATRIX_FILE="$MATRIX_DIR/matrix.tab"

if [ -e $MATRIX_FILE ]; then
  rm -f $MATRIX_FILE
fi

$SCRIPT_DIR/make-matrix.pl -d $MODE_DIR > $MATRIX_FILE

#$SCRIPT_DIR/sna.pl -s $MATRIX_FILE -o $MATRIX_DIR 

echo Finished $(date)
