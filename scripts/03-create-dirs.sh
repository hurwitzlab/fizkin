#!/bin/bash

# 
# Prepare a directory structure for every read-to-read count
# 

souce ./config.sh

PROG=`basename $0 ".sh"`
ERR_DIR=$CWD/err/$PROG
OUT_DIR=$CWD/out/$PROG

create_dirs $ERR_DIR $OUT_DIR

export CWD=$PWD

if [[ ! -d $COUNT_DIR ]]; then
    mkdir $COUNT_DIR
fi

echo Checking for needed count directory structure
cd $FASTA_DIR
for DIR1 in `find . -maxdepth 1 -type d`; do
    if [ "$DIR1" = '.' ]; then
        continue
    fi

    for DIR2 in `find . -maxdepth 1 -type d`; do
        if [ "$DIR2" = '.' ]; then
            continue
        fi

        DEST=`readlink -f $COUNT_DIR/$DIR1/$DIR2`
        if [[ ! -d $DEST ]]; then
            echo Making $DEST
            mkdir -p $DEST
        fi
    done
done
