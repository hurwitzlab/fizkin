#!/bin/bash

#
# Run tallymer search for every read against every index
#

source ./config.sh

CWD=$PWD
PROG=`basename $0 ".sh"`
STDERR_DIR="$CWD/err/$PROG"
STDOUT_DIR="$CWD/out/$PROG"
JOB_INFO_DIR="$CWD/job-info/$PROG"

create_dirs "$STDERR_DIR" "$STDOUT_DIR" "$JOB_INFO_DIR"

export SUFFIX_DIR=$HOST_JELLYFISH_DIR

if [[ ! -d "$COUNT_DIR" ]]; then
    mkdir "$COUNT_DIR"
fi

if [[ ! -d "$KMER_DIR" ]]; then
    mkdir "$KMER_DIR"
fi

echo Processing FASTA in \"$FASTA_DIR\"
cd $FASTA_DIR

i=0
for FILE in DNA*.fa; do
    export FASTA="$FASTA_DIR/$FILE"

    JOB_ID=`qsub -N "query" -e "$STDERR_DIR/$FILE" -o "$STDOUT_DIR/$FILE" -v SCRIPT_DIR,SUFFIX_DIR,COUNT_DIR,KMER_DIR,FASTA,MER_SIZE,JELLYFISH $SCRIPT_DIR/launch-jellyfish-query.sh`

    $QSTAT -f $JOB_ID > "$JOB_INFO_DIR/$FILE"

    i=$((i+1))
    printf "%8d: %s %s\n" $i $JOB_ID $FILE 
done

echo Submitted $i jobs for you.  Namaste.
