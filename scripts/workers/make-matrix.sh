#!/bin/bash

#PBS -q standard
#PBS -l jobtype=cluster_only
#PBS -l select=1:ncpus=6:mem=10gb
#PBS -l place=pack:exclhost
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

# --------------------------------------------------
set -u

echo Started $(date)

echo Host $(hostname)

if [[ ! -d $MATRIX_DIR ]]; then
  mkdir -p $MATRIX_DIR
fi

MATRIX_FILE="$MATRIX_DIR/matrix.tab"

if [ -e $MATRIX_FILE ]; then
  rm -f $MATRIX_FILE
fi

$SCRIPT_DIR/make-matrix.pl -r 'DNA_[1-4]' -d $MODE_DIR > $MATRIX_FILE

echo Matrix created in \"$MATRIX_FILE\"

echo Finished $(date)
