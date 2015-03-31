#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

# --------------------------------------------------
function lc() {
    wc -l $1 | cut -d ' ' -f 1
}

# --------------------------------------------------
echo Started `date`

echo Host `hostname`

source /usr/share/Modules/init/bash

$SCRIPT_DIR/make-matrix.pl -d $MODE_DIR > $MATRIX_DIR/matrix

echo Finished `date`
