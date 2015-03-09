#!/bin/bash

source ./config.sh

export CWD="$PWD"

PROG=`basename $0 ".sh"`
ERR_DIR="$CWD/err"
OUT_DIR="$CWD/out"

create_dirs "$ERR_DIR" "$OUT_DIR"

export DIR="$COUNT_DIR"

JOB_ID=`qsub -v DIR -N sum -e "$ERR_DIR/$PROG" -o "$OUT_DIR/$PROG" $SCRIPT_DIR/sum-hits.sh`

echo Submitted $JOB_ID
