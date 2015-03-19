#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=4:mem=23gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

# Expects: DIR

echo Hostname `hostname`

echo Started `date`

echo Summarizing hits in dir \"$DIR\"

OUT_FILE="$DIR/sum"

SORT="/rsgrps/bhurwitz/hurwitzlab/bin/sort --parallel 4 -u"

TMPDIR="$DIR/tmp"

if [[ ! -d $TMPDIR ]]; then
    mkdir -p $TMPDIR
fi

find "$DIR" -type f -print0 | xargs -0 $SORT -T "$TMPDIR" > $OUT_FILE

NUM_HITS=`wc -l $OUT_FILE | cut -f 1 -d ' '`

echo Found $NUM_HITS hits

echo Ended `date`
