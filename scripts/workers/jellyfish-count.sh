#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

# Expects: SOURCE_DIR, MER_SIZE, FILES_LIST, JELLYFISH, OUT_DIR 

echo Started `date`

echo Host `hostname`

source /usr/share/Modules/init/bash

THREADS=4
HASH_SIZE="100M"

# FILE=`head -n +${PBS_ARRAY_INDEX} $FILES_LIST | tail -n 1`

FILES=$TMPDIR/files

if [ "${PBS_ARRAY_INDEX}x" == "x" ]; then
    cp $FILES_LIST $FILES
else
    head -n +${PBS_ARRAY_INDEX} $FILES_LIST | tail -n 1 > $FILES
fi

NUM_FILES=`wc -l $FILES | cut -d ' ' -f 1`

echo Processing \"$NUM_FILES\" files

echo cd "$SOURCE_DIR"
cd "$SOURCE_DIR"

i=0
while read FILE; do
    OUT_FILE="$OUT_DIR/$FILE.jf"

    if [ -e "$OUT_FILE" ]; then
        rm -f "$OUT_FILE";
    fi

    let i++
    printf "%5d: %s\n" $i $FILE

    $JELLYFISH count -C -m $MER_SIZE -s $HASH_SIZE -t $THREADS -o $OUT_FILE $FILE
done < $FILES

echo Finished `date`
