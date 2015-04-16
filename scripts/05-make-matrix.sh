#!/bin/sh

# --------------------------------------------------
#
# 05-make-matrix.sh
#
# Reduce the "modes" into a matrix needed for 
# analysis in R
#
# --------------------------------------------------

set -u

source ./config.sh

CWD=$PWD
PROG=$(basename $0 ".sh")
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$STDERR_DIR" "$STDOUT_DIR" "$MATRIX_DIR"

JOB=$(qsub -N "mk-matrix" -j oe -o "$STDOUT_DIR" -v SCRIPT_DIR,MODE_DIR,MATRIX_DIR $SCRIPT_DIR/make-matrix.sh)

if [ $? -eq 0 ]; then
  echo Submitted job \"$JOB.\" Do svidaniya.
else
  echo -e "\nError submitting job\n$JOB\n"
fi
