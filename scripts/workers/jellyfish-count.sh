#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

source /usr/share/Modules/init/bash

cd "$FASTA_DIR"

OUT_FILE=`basename "$FILE" ".fa"`
BLOOM="$JELLYFISH_DIR/$OUT_FILE.bc"
JF="$JELLYFISH_DIR/$OUT_FILE.jf"
THREADS=8
HASH_SIZE="100M"

if [ -e "$BLOOM" ]; then
    rm -f "$BLOOM";
fi

if [ -e "$OUT_FILE" ]; then
    rm -f "$OUT_FILE";
fi

date
echo Making Bloom filter
echo $JELLYFISH bc -m $MER_SIZE -s $HASH_SIZE -t $THREADS -o "$BLOOM" "$FILE"

$JELLYFISH bc -m $MER_SIZE -s $HASH_SIZE -t $THREADS -o "$BLOOM" "$FILE"

echo
date
echo Jellyfish count
echo $JELLYFISH count -C -m $MER_SIZE -s $HASH_SIZE -t $THREADS -o $JF --bc "$BLOOM" "$FILE"

$JELLYFISH count -C -m $MER_SIZE -s $HASH_SIZE -t $THREADS -o $JF --bc "$BLOOM" "$FILE"

echo
date
echo Finished
