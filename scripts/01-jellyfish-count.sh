#!/bin/bash

#
# Create k-mer suffix arrays from a directory of FASTA files
#

source ./config.sh

export CWD=$PWD

PROG=`basename "$0" ".sh"`
ERR_DIR="$CWD/err/$PROG"
OUT_DIR="$CWD/out/$PROG"

create_dirs "$ERR_DIR" "$OUT_DIR"

export SOURCE_DIR=$HOST_DIR
export OUT_DIR=$HOST_JELLYFISH_DIR

if [[ ! -d "$OUT_DIR" ]]; then
    mkdir "$OUT_DIR"
fi

cd "$SOURCE_DIR"

export FILES_LIST="$SOURCE_DIR/files-list"

find -maxdepth 1 -type f -name \*.fa > $FILES_LIST

COUNT=`wc -l $FILES_LIST | cut -d ' ' -f 1`

echo Found $COUNT files in \"$SOURCE_DIR\"

if [ $COUNT -gt 0 ]; then
    JOB_ID=`qsub -N jellyfish -e "$ERR_DIR/$FASTA" -o "$OUT_DIR/$FASTA" \
        -v SOURCE_DIR,MER_SIZE,FILES_LIST,JELLYFISH,OUT_DIR -J 1-$COUNT \
        $SCRIPT_DIR/jellyfish-count.sh`

    echo Job ID: \"$JOB_ID\"
else
    echo Nothing to do!
fi
