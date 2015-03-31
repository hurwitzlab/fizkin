#!/bin/sh

# --------------------------------------------------
#
# 05-make-matrix.sh
#
# Create the matrix needed for R
#
# --------------------------------------------------

set -u
source ./config.sh

CWD=$PWD
PROG=$(basename $0 ".sh")
STDERR_DIR="$CWD/err/$PROG"
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$STDERR_DIR" "$STDOUT_DIR" "$MATRIX_DIR"

JOB=$(qsub -N "mk-matrix" -e "$STDERR_DIR" -o "$STDOUT_DIR" -v SCRIPT_DIR,MODE_DIR,MATRIX_DIR $SCRIPT_DIR/make-matrix.sh)

if [ $? -eq 0 ]; then
    echo Submitted job \"$JOB.\" Do svidaniya.
else
    echo -e "\nError submitting job\n$JOB\n"
fi
