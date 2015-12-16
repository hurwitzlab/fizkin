#!/bin/bash

#PBS -q standard
#PBS -l jobtype=cluster_only
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l pvmem=20gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

set -u
module load fastx
for file in /usr/share/Modules/init/bash ~/bin/common.sh; do
  source $file
done

if [[ -z "$FASTA_DIR" ]]; then
  echo FASTA_DIR is undefined.
  exit
fi

if [[ ! -d $FASTA_DIR ]]; then
  echo FASTA_DIR \"$FASTA_DIR\" does not exist.
  exit
fi

if [[ -z "$FILES_LIST" ]]; then
  echo FILES_LIST is undefined.
  exit
fi

TMP_FILES=$(mktemp)

get_lines $FILES_LIST $TMP_FILES ${PBS_ARRAY_INDEX:-1} ${STEP_SIZE:-1}

i=0
while read FASTQ; do
  let i++
  printf "%5d: %s\n" $i $FASTQ
  BASENAME=$(basename $FASTQ)
  TYPE=$(file -ib $FASTQ | sed "s/;.*//") 

  if [[ $TYPE == 'application/x-gzip' ]]; then
      gunzip $FASTQ
      FASTQ=${FASTQ%\.*} # remove last extension
  fi

  FASTA=$(basename ${FASTQ%\.*}).fa

  if [[ ! -e $FASTA ]]; then
    fastq_to_fasta -i $FASTQ -o $FASTA_DIR/$FASTA
  fi
done < $TMP_FILES

echo Done, processed $i files
