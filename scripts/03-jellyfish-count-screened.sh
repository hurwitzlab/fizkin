#!/bin/bash

# --------------------------------------------------
#
# 03-jellyfish-count-screened.sh
#
# Index host-screened FASTA for pairwise analysis
#
# --------------------------------------------------

#set -ux

source ./config.sh
export SOURCE_DIR="$FASTA_DIR"
export OUT_DIR="$JELLYFISH_DIR"
export CWD="$PWD"

# --------------------------------------------------

PROG=$(basename "$0" ".sh")
STDERR_DIR="$CWD/err/$PROG"
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$STDERR_DIR" "$STDOUT_DIR" "$OUT_DIR"

export FILES_LIST="$SOURCE_DIR/files-list"

cd "$SOURCE_DIR"

find . -name \*.fa | sed "s/^\.\///" > $FILES_LIST

NUM_FILES=$(lc $FILES_LIST)

echo Found \"$NUM_FILES\" files in \"$SOURCE_DIR\"

if [ -z $NUM_FILES ] || [ $NUM_FILES -lt 1 ]; then
    echo Nothing to do!
else
    JOB_ID=`qsub -N jf_self -J 1-$NUM_FILES -e "$STDERR_DIR" -o "$STDOUT_DIR" -v SCRIPT_DIR,SOURCE_DIR,MER_SIZE,FILES_LIST,JELLYFISH,KMER_DIR,OUT_DIR $SCRIPT_DIR/jellyfish-count.sh`
    echo Submitted \"$JOB_ID\" for you.  Shalom.
fi
