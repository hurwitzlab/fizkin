#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

source /usr/share/Modules/init/bash

cd "$SOURCE_DIR"

OUT_FILE=`basename "$FILE" ".fa"`
BLOOM="$OUT_DIR/$OUT_FILE.bc"
JF="$OUT_DIR/$OUT_FILE.jf"
THREADS=8
HASH_SIZE="100M"

if [ -e "$BLOOM" ]; then
    rm -f "$BLOOM";
fi

if [ -e "$OUT_FILE" ]; then
    rm -f "$OUT_FILE";
fi

#echo Making Bloom filter
#$JELLYFISH bc -m $MER_SIZE -s $HASH_SIZE -t $THREADS -o "$BLOOM" "$FILE"

echo Jellyfish count

# $JELLYFISH count -C -m $MER_SIZE -s $HASH_SIZE -t $THREADS -o $JF --bc "$BLOOM" "$FILE"

$JELLYFISH count -C -m $MER_SIZE -s $HASH_SIZE -t $THREADS -o $JF "$FILE"

echo Finished
