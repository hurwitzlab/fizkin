#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00
#PBS -M scottdaniel@email.arizona.edu
#PBS -m ea

# Expects: SOURCE_DIR, MER_SIZE, FILES_LIST, JELLYFISH, OUT_DIR

COMMON="$SCRIPT_DIR/common.sh"

if [ -e $COMMON ]; then
  . "$COMMON"
else
  echo Missing common \"$COMMON\"
  exit 1
fi

set -u

echo Started $(date)

echo Host $(hostname)

source /usr/share/Modules/init/bash

module load bowtie2/2.2.5

if [ -z $SRC_DIR ]; then
  echo Missing SRC_DIR
  exit 1
fi

if [ -z $TARGET_DIR ]; then
  echo Missing TARGET_DIR
  exit 1
fi

if [[ ! -d $SRC_DIR ]]; then
  echo Bad source directory \"$SRC_DIR\"
fi

if [[ ! -d $TARGET_DIR ]]; then
  mkdir -p $TARGET_DIR
fi

cd "$SRC_DIR"

TMP_FILES=$(mktemp)

find . -type f > $TMP_FILES

NUM_FILES=$(lc $TMP_FILES)

echo Found \"$NUM_FILES\" files to process

i=0
while read FILE; do
  BASENAME=$(basename $FILE)
  NO_EXT=${BASENAME%.*}

  let i++
  printf "%5d: %s\n" $i $BASENAME

  bowtie2-build $SRC_DIR/$BASENAME $TARGET_DIR/$NO_EXT > /dev/null 
done < $TMP_FILES

echo Finished $(date)
