#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=cluster_only
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00
#PBS -M scottdaniel@email.arizona.edu
#PBS -m ea

# Expects:
# STEP_SIZE SCRIPT_DIR FILES_LIST BT_ALIGNED_DIR

set -u

source /usr/share/Modules/init/bash

module load bowtie2/2.2.5

COMMON="$SCRIPT_DIR/common.sh"

if [ -e $COMMON ]; then
  . "$COMMON"
else
  echo Missing common \"$COMMON\"
  exit 1
fi


echo Host \"$(hostname)\"

echo Started $(date)

TMP_FILES=$(mktemp)

get_lines $FILES_LIST $TMP_FILES $PBS_ARRAY_INDEX $STEP_SIZE

NUM_FILES=$(lc $TMP_FILES)

echo Found \"$NUM_FILES\" files to process

i=0
while read BT_FILE FASTA_FILE; do
  BT_BASENAME=$(basename $BT_FILE)
  FA_BASENAME=$(basename $FASTA_FILE)
  let i++
  printf "%5d: %s %s\n" $i $BT_BASENAME $FA_BASENAME

  BT_DIRNAME=$(dirname $BT_FILE)
  BT_DIRNAME=$(basename $BT_DIRNAME)

  OUT_DIR=$BT_ALIGNED_DIR/$BT_DIRNAME/$BT_BASENAME

  if [[ ! -e $OUT_DIR ]]; then
    mkdir -p $OUT_DIR
  fi

  bowtie2 -k 1 -f -U $FASTA_FILE -x $BT_FILE --al $OUT_DIR/$FA_BASENAME > /dev/null
done < $TMP_FILES

echo Finished $(date)
