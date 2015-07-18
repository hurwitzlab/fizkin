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

init_dirs "$STDOUT_DIR" "$MATRIX_DIR"

EMAIL_ARG=""
if [[ ! -z $EMAIL ]]; then
  EMAIL_ARG="-M $EMAIL -m ea"
fi

GROUP_ARG="-W group_list=${GROUP:=bhurwitz}"

JOB=$(qsub -N "mk-matrix" -j oe -o "$STDOUT_DIR" $EMAIL_ARG $GROUP_ARG -v SCRIPT_DIR,MODE_DIR,MATRIX_DIR $SCRIPT_DIR/make-matrix.sh)

if [ $? -eq 0 ]; then
  echo Submitted job \"$JOB.\" Do svidaniya.
else
  echo -e "\nError submitting job\n$JOB\n"
fi
