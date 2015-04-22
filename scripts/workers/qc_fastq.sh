#!/bin/bash

#PBS -W group_list=gwatts
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=2:mem=5gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00
#PBS -M kyclark@email.arizona.edu
#PBS -m ea

#
# Runs QC on a set of paired-end Illumina FASTQ files
#

# expects: 
# SCRIPT_DIR RAW_DIR BIN_DIR FILE FASTQ_DIR FASTA_DIR 

# --------------------------------------------------
# R is needed by the SolexaQA++ program
module load R
# --------------------------------------------------

COMMON="$SCRIPT_DIR/common.sh"

if [ -e $COMMON ]; then
  . "$COMMON"
else
  echo Missing common \"$COMMON\"
  exit 1
fi

set -u

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
  printf "%5d: %s\n" $i $BASENAME

  for F in $FASTQ_DIR/${BASENAME}*; do
    rm -f $F
  done

  TRIMMED_FILE=$FASTQ_DIR/${BASENAME}.trimmed

  if [[ ! -e $TRIMMED_FILE ]]; then
    for ACTION in analysis dynamictrim; do
      $BIN_DIR/SolexaQA++ $ACTION -d $FASTQ_DIR $FILE
    done
  fi

  if [[ ! -s $TRIMMED_FILE ]]; then
    echo Failed to create trimmed file \"$TRIMMED_FILE\"
    continue
  fi
  
  CLIPPED_FILE=${TRIMMED_FILE}.clipped

  $BIN_DIR/fastx_clipper -v -l ${MIN_SEQ_LENGTH:=50} \
    -i $TRIMMED_FILE -o $CLIPPED_FILE

  if [[ ! -s $CLIPPED_FILE ]]; then
    echo Failed to create clipped file \"$CLIPPED_FILE\"
    continue
  fi

  FASTA=$(basename $FILE '.fastq')

  $SCRIPT_DIR/fastq2fasta.awk $CLIPPED_FILE > "${FASTA_DIR}/${FASTA}.fa"
done < $TMP_FILES

echo Finished $(date)
