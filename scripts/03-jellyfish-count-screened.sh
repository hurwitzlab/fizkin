#!/bin/bash

#
# 03-jellyfish-count-screened.sh
# Index host-screened FASTA for pairwise analysis
#

source ./config.sh
export SOURCE_DIR="$SCREENED_DIR"
export OUT_DIR="$JELLYFISH_DIR"
export CWD="$PWD"

# --------------------------------------------------

PROG=`basename "$0" ".sh"`
STDERR_DIR="$CWD/err/$PROG"
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$STDERR_DIR" "$STDOUT_DIR" "$OUT_DIR"

export FILES_LIST="$SOURCE_DIR/files-list"

cd "$SOURCE_DIR"

find . -name \*.screened | sed "s/^\.\///" > $FILES_LIST

NUM_FILES=`wc -l $FILES_LIST | cut -d ' ' -f 1`

echo Found \"$NUM_FILES\" files in \"$SOURCE_DIR\"

if [ $NUM_FILES -eq 0 ]; then
    echo Nothing to do!
else
    JOB_ID=`qsub -N jf_self -J 1-$NUM_FILES -e "$STDERR_DIR" -o "$STDOUT_DIR" -v SOURCE_DIR,MER_SIZE,FILES_LIST,JELLYFISH,OUT_DIR $SCRIPT_DIR/jellyfish-count.sh`
    echo Submitted \"$JOB_ID\" for you.  Shalom.
fi
