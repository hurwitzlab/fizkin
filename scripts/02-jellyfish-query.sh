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

if [[ ! -d "$KMER_DIR" ]]; then
    mkdir "$KMER_DIR"
fi

echo Processing FASTA in \"$FASTA_DIR\"
cd $FASTA_DIR

i=0
for FILE in *.fa; do
    export FASTA="$FASTA_DIR/$FILE"

    JOB_ID=`qsub -N "query" -e "$ERR_DIR/$FILE" -o "$OUT_DIR/$FILE" -v SCRIPT_DIR,JELLYFISH_DIR,COUNT_DIR,KMER_DIR,FASTA,MER_SIZE,JELLYFISH $SCRIPT_DIR/launch-jellyfish-query.sh`

    i=$((i+1))
    printf "%8d: %s %s\n" $i $JOB_ID $FILE 
    break
done

echo Submitted $i jobs for you.  Namaste.
