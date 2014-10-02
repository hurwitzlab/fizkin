#!/bin/bash

#
# In the suffix dir, the directories are named by the original FASTA
# file names, e.g., "POV_GD.Spr.C.8m_reads".  Inside the directories,
# there will be 12 files generated for the suffix array.  We need to 
# find the ".tyr-reads" file (there are 3, we just need the uniq 
# basename) to give to the "gt tallymer search" command.
#

source ./config.sh

PROG=`basename $0 ".sh"`
ERR_DIR=$CWD/err/$PROG
OUT_DIR=$CWD/out/$PROG

create_dirs $ERR_DIR $OUT_DIR

export CWD=$PWD

if [[ ! -d $COUNT_DIR ]]; then
    mkdir $COUNT_DIR
fi

echo Making index file list
cd $SUFFIX_DIR
export INDEX_FILE=`readlink -f $SUFFIX_DIR/index-files`

if [ -e $INDEX_FILE ]; then
    rm $INDEX_FILE
fi

i=0
for DIR in `find . -maxdepth 1 -type d`; do
    if [ "$DIR" = '.' ]; then
        continue
    fi

    i=$((i + 1))
    printf "%5d: %s" $i `basename $DIR`
    echo

    #
    # We want the full path in the index file
    #
    ls $PWD/$DIR/*.tyr-reads.mer | sed "s/\.mer//" > $DIR/indexes
    echo `readlink -f $DIR/indexes` >> $INDEX_FILE
done
