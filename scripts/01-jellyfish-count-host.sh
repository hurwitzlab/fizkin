#!/bin/bash

# 01-jellyfish-count-host.sh
#
# Use Jellyfish to index host FASTA
# --------------------------------------------------

source ./config.sh
export SOURCE_DIR="$HOST_DIR"
export OUT_DIR="$HOST_JELLYFISH_DIR"

# --------------------------------------------------

export CWD=$PWD

PROG=`basename "$0" ".sh"`
STDERR_DIR="$CWD/err/$PROG"
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$ERR_DIR" "$OUT_DIR"

cd "$SOURCE_DIR"

export FILES_LIST="$SOURCE_DIR/files-list"

find -maxdepth 1 -type f -name \*.fa > $FILES_LIST

COUNT=`wc -l $FILES_LIST | cut -d ' ' -f 1`

echo Found \"$COUNT\" files in \"$SOURCE_DIR\"

if [ $COUNT -gt 0 ]; then
    JOB_ID=`qsub -N jf_host -e "$STDERR_DIR" -o "$STDOUT_DIR" -J 1-$COUNT \
        -v SOURCE_DIR,MER_SIZE,FILES_LIST,JELLYFISH,OUT_DIR 
        $SCRIPT_DIR/jellyfish-count.sh`

    echo Submitted \"$JOB_ID\" for you.  Aloha.
else
    echo Nothing to do.
fi
