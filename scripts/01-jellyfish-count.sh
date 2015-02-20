#!/bin/bash

#
# Create k-mer suffix arrays from a directory of FASTA files
#

source ./config.sh

export CWD=$PWD

PROG=`basename $0 ".sh"`
STDERR_DIR="$CWD/err/$PROG"
STDOUT_DIR="$CWD/out/$PROG"

export SOURCE_DIR=$HOST_DIR
export OUT_DIR=$HOST_JELLYFISH_DIR

create_dirs "$STDERR_DIR" "$STDOUT_DIR" "$OUT_DIR"

cd "$SOURCE_DIR"
COUNT=`find -maxdepth 1 -type f -name \*.fa | wc -l`
echo Found $COUNT files in \"$SOURCE_DIR\"

i=0
for FASTA in *.fa; do
    i=$((i+1))

    export FILE=`readlink -f $FASTA`

    JOB_ID=`qsub -N jellyfish -e "$STDERR_DIR/$FASTA" -o "$STDOUT_DIR/$FASTA" -v SOURCE_DIR,MER_SIZE,FILE,JELLYFISH,OUT_DIR $SCRIPT_DIR/jellyfish-count.sh`

    $QSTAT -f $JOB_ID > "$STDOUT_DIR/$FASTA"

    printf "%5d: %s %s\n" $i $JOB_ID $FASTA
done

echo Submitted $i jobs for you.  Have a nice day.
