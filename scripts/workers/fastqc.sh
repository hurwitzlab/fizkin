#!/bin/bash

#PBS -q standard
#PBS -l jobtype=cluster_only
#PBS -l select=1:ncpus=6:mem=11gb
#PBS -l pvmem=22gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

#
# Runs fastQC on a set of paired-end Illumina FASTQ files
#
# --------------------------------------------------
# stuff needed 
module load java fastqc 
# --------------------------------------------------

set -u

COMMON="$WORKER_DIR/common.sh"

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
while read FILE; do
  BASENAME=$(basename $FILE)
  let i++
  printf "Processing %5d: %s\n" $i $BASENAME

  echo "just testing... normally this would launch fastqc"
#  fastqc -o $FASTQC_REPORTS $FILE 
#
#  TRIMMED_FILE=$FASTQ_DIR/${BASENAME}.trimmed
#
#  if [[ ! -e $TRIMMED_FILE ]]; then
#    for ACTION in analysis dynamictrim; do
#      $BIN_DIR/SolexaQA++ $ACTION -d $FASTQ_DIR $FILE
#    done
#  fi
#
#  if [[ ! -s $TRIMMED_FILE ]]; then
#    echo Failed to create trimmed file \"$TRIMMED_FILE\"
#    continue
#  fi
#
#  CLIPPED_FILE=${TRIMMED_FILE}.clipped
#
#  $BIN_DIR/fastx_clipper -v -l ${MIN_SEQ_LENGTH:=52} \
#    -i $TRIMMED_FILE -o $CLIPPED_FILE
#
#  if [[ ! -e $CLIPPED_FILE ]]; then
#    echo Failed to create clipped file \"$CLIPPED_FILE\"
#    continue
#  fi
#
#  if [[ ! -s $CLIPPED_FILE ]]; then
#    echo Created zero-length clipped file \"$CLIPPED_FILE\"
#    continue
#  fi
#
#  FASTA=$(basename $FILE '.fastq')
#
#  $WORKER_DIR/fastq2fasta.awk $CLIPPED_FILE > "${FASTA_DIR}/${FASTA}.fa"
done < $TMP_FILES

echo Finished $(date)
