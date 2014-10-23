#!/bin/bash

#
# Create k-mer suffix arrays from a directory of FASTA files
#

source ./config.sh

export CWD=$PWD

PROG=`basename $0 ".sh"`
ERR_DIR="$CWD/err/$PROG"
OUT_DIR="$CWD/out/$PROG"

create_dirs "$ERR_DIR" "$OUT_DIR"

if [[ ! -d "$JELLYFISH_DIR" ]]; then
    mkdir "$JELLYFISH_DIR"
fi

cd "$FULL_FASTA_DIR"

i=0
for FILE in *.fa; do
    export FILE
    JOB_ID=`qsub -N jellyfish -e "$ERR_DIR/$FILE" -o "$OUT_DIR/$FILE" -v FULL_FASTA_DIR,MER_SIZE,FILE,JELLYFISH,JELLYFISH_DIR $SCRIPT_DIR/jellyfish-count.sh`

    i=$((i+1))
    printf "%5d: %s %s" $i $JOB_ID $FILE
    echo
done

echo Submitted $i jobs for you.  Have a nice day.
