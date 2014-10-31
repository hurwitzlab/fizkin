#!/bin/bash

#
# Run tallymer search for every read against every index
#

source ./config.sh

CWD=$PWD
PROG=`basename $0 ".sh"`
ERR_DIR="$CWD/err/$PROG"
OUT_DIR="$CWD/out/$PROG"

create_dirs "$ERR_DIR" "$OUT_DIR"

if [[ ! -d "$COUNT_DIR" ]]; then
    mkdir "$COUNT_DIR"
fi

echo Processing suffixes in \"$JELLYFISH_DIR\"
cd $JELLYFISH_DIR

i=0
for FILE in *.jf; do
    export SUFFIX="$JELLYFISH_DIR/$FILE"

    JOB_ID=`qsub -N "query" -e "$ERR_DIR/$FILE" -o "$OUT_DIR/$FILE" -v SCRIPT_DIR,SUFFIX,COUNT_DIR,MER_SIZE,JELLYFISH,KMER_DIR $SCRIPT_DIR/launch-jellyfish-query.sh`

    i=$((i+1))
    printf "%8d: %s %s\n" $i $JOB_ID $FILE 
done

echo Submitted $i jobs for you.  Namaste.
