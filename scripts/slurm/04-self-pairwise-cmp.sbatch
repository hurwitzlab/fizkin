#!/bin/bash

# Use Jellyfish to run a pairwise comparison of all screened samples

set -u
 
#SBATCH -p normal
#SBATCH -n 4
#SBATCH -A iPlant-Collabs
#SBATCH -J pair-cmp
#SBATCH -o out/pair-cmp.o%j 
#SBATCH -t 24:00:00
#SBATCH --mail-user=kyclark@email.arizona.edu
#SBATCH --mail-type=end
 
module load launcher
PATH=$TACC_LAUNCHER_DIR:$PWD/workers:$PATH

export LAUNCHER_PPN=100

source ../config.sh
export SUFFIX_DIR="$JELLYFISH_DIR"
export OUT_DIR="$MODE_DIR"

# --------------------------------------------------
function lc {
    wc -l $1 | cut -d ' ' -f 1
}

# --------------------------------------------------

CWD=$PWD
PROG=`basename $0 ".sh"`
STDERR_DIR="$CWD/err/$PROG"
STDOUT_DIR="$CWD/out/$PROG"
JOB_INFO_DIR="$CWD/job-info/$PROG"

init_dirs "$STDERR_DIR" "$STDOUT_DIR" "$JOB_INFO_DIR"

if [[ ! -d "$OUT_DIR" ]]; then
    mkdir "$OUT_DIR"
fi

if [[ ! -d "$KMER_DIR" ]]; then
    mkdir "$KMER_DIR"
fi

#
# Find input files
#
export INPUT_FILES_LIST=$(mktemp)
echo INPUT_FILES_LIST $INPUT_FILES_LIST
echo SCREENED_DIR $SCREENED_DIR
find $SCREENED_DIR -name \*.screened > $INPUT_FILES_LIST
NUM_INPUT_FILES=`lc $INPUT_FILES_LIST`

if [ $NUM_INPUT_FILES -lt 1 ]; then
    echo Cannot find any screened files in \"$SCREENED_DIR\";
    exit 1
fi

#
# Find suffix arrays (Jellyfish indexes)
#
export SUFFIX_FILES_LIST="$SUFFIX_DIR/files-list"
find $SUFFIX_DIR -name \*.jf > $SUFFIX_FILES_LIST
NUM_SUFFIX_FILES=`lc $SUFFIX_FILES_LIST`

if [ $NUM_SUFFIX_FILES -lt 1 ]; then
    echo Cannot find any suffix arrays in \"$SUFFIX_DIR\";
    exit 1
fi

if [ $NUM_SUFFIX_FILES -ne $NUM_INPUT_FILES ]; then
    echo Num input files \"$NUM_INPUT_FILES\" not equal to num suffix arrays \"$NUM_SUFFIX_FILES\"
    exit 1
fi

echo Processing \"$NUM_INPUT_FILES\" files/arrays

PARAMS=$(basename $0).params
if [ -e $PARAMS ]; then
    rm $PARAMS
fi

while read INPUT_FILE; do
    while read SUFFIX_FILE; do
        echo "FASTA=$INPUT_FILE SUFFIX=$SUFFIX_FILE OUT_DIR=$OUT_DIR KMER_DIR=$KMER_DIR JELLYFISH=$JELLYFISH $SCRIPT_DIR/workers/pairwise-cmp.sh" >> $PARAMS
    done < $SUFFIX_FILES_LIST
done < $INPUT_FILES_LIST

echo PARAMS \"$PARAMS\";

paramrun init_launcher $PARAMS
