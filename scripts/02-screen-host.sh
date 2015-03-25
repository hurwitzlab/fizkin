#!/bin/bash

#
# Run Jellyfish query for every read against every index
#

source ./config.sh

CWD=$PWD
PROG=`basename $0 ".sh"`
STDERR_DIR="$CWD/err/$PROG"
STDOUT_DIR="$CWD/out/$PROG"
JOB_INFO_DIR="$CWD/job-info/$PROG"

init_dirs "$STDERR_DIR" "$STDOUT_DIR" "$JOB_INFO_DIR"

export SUFFIX_DIR=$HOST_JELLYFISH_DIR

if [[ ! -d "$COUNT_DIR" ]]; then
    mkdir "$COUNT_DIR"
fi

if [[ ! -d "$KMER_DIR" ]]; then
    mkdir "$KMER_DIR"
fi

export FILES_LIST="$FASTA_DIR/file-list";

cd $FASTA_DIR

find . -name DNA\*.fa > $FILES_LIST

NUM_FILES=`wc -l $FILES_LIST | cut -d ' ' -f 1`

if [ $NUM_FILES -gt 0 ]; then
    echo Processing $NUM_FILES FASTA files in \"$FASTA_DIR\"

    JOB_ID=`qsub -N "query" -J 1-$NUM_FILES -e "$STDERR_DIR" -o "$STDOUT_DIR" -v FASTA_DIR,SCRIPT_DIR,SUFFIX_DIR,COUNT_DIR,SCREENED_DIR,KMER_DIR,MER_SIZE,JELLYFISH,FILES_LIST $SCRIPT_DIR/launch-jellyfish-query.sh`

    echo Submitted \"$JOB_ID\" for you.  Namaste.
else
    echo Could not find any files in \"${FASTA_DIR}.\"
fi
