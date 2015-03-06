#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

# Expects: SOURCE_DIR, MER_SIZE, FILES_LIST, JELLYFISH, OUT_DIR 

echo Started `date`

source /usr/share/Modules/init/bash

cd "$SOURCE_DIR"

FILE=`head -n +${PBS_ARRAY_INDEX} $FILES_LIST | tail -n 1`
BASENANE=`basename "$FILE" ".fa"`
OUT_FILE="$OUT_DIR/$BASENANE.jf"
THREADS=12
HASH_SIZE="100M"

if [ -e "$OUT_FILE" ]; then
    rm -f "$OUT_FILE";
fi

echo Counting $FILE

$JELLYFISH count -C -m "$MER_SIZE" -s "$HASH_SIZE" \ 
  -t "$THREADS" -o "$OUT_FILE" "$FILE"

echo Finished `date`
