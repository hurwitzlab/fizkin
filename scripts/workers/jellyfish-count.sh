#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q windfall
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=12:mem=10gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

source /usr/share/Modules/init/bash

cd $FULL_FASTA_DIR

OUT_FILE=`basename "$FILE" ".fa"`
BLOOM="$JELLYFISH_DIR/$OUT_FILE.bc"
JF="$JELLYFISH_DIR/$OUT_FILE.jf"
THREADS=4
HASH_SIZE="100M"

if [ -e "$BLOOM" ]; then
    rm -f "$BLOOM";
fi

if [ -e "$OUT_FILE" ]; then
    rm -f "$OUT_FILE";
fi

$JELLYFISH bc -m $MER_SIZE -s $HASH_SIZE -t $THREADS -o "$BLOOM" "$FILE"

$JELLYFISH count -C -m $MER_SIZE -s $HASH_SIZE -t $THREADS -o $JF --bc "$BLOOM" "$FILE"
