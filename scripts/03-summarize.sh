#!/bin/bash

source ./config.sh

export CWD="$PWD"

PROG=`basename $0 ".sh"`
ERR_DIR="$CWD/err/$PROG"
OUT_DIR="$CWD/out/$PROG"

init_dirs "$ERR_DIR" "$OUT_DIR"

export DIR="$COUNT_DIR"

JOB_ID=`qsub -v DIR -N sum -e "$ERR" -o "$OUT" $SCRIPT_DIR/sum-hits.sh`

echo Submitted job \"$JOB_ID\"
