#!/bin/bash

#PBS -W group_list=mbsulli
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=2:mem=10gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00
#PBS -M kyclark@email.arizona.edu
#PBS -m ea

# Expects:
# FILES_LIST DATA_DIR SCRIPT_DIR HOST_JELLYFISH_DIR 
# SCREENED_DIR KMER_DIR MER_SIZE JELLYFISH STEP_SIZE 

source /usr/share/Modules/init/bash

set -u

COMMON="$SCRIPT_DIR/common.sh"

if [ -e $COMMON ]; then
  . "$COMMON"
else
  echo Missing common \"$COMMON\"
  exit 1
fi

echo Started $(date)

echo Host $(hostname)

#
# Find out what our input FASTA file is
#
if [[ ! -e $FILES_LIST ]]; then
  echo Cannot find files list \"$FILES_LIST\"
  exit 1
fi

TMP_FILES=$(mktemp)

get_lines $FILES_LIST $TMP_FILES ${PBS_ARRAY_INDEX:=1} $STEP_SIZE

NUM_FILES=$(lc $TMP_FILES)

echo Processing \"$NUM_FILES\" input files

if [ $NUM_FILES -lt 0 ]; then
  echo Could not get FASTA files from \"$FILES_LIST\"
  exit 1
fi

SUFFIX_LIST=$(mktemp)

find $HOST_JELLYFISH_DIR -name \*.jf > $SUFFIX_LIST

NUM_SUFFIXES=$(wc -l $SUFFIX_LIST | cut -d ' ' -f 1)

echo Found \"$NUM_SUFFIXES\" suffixes in \"$HOST_JELLYFISH_DIR\"

if [ $NUM_SUFFIXES -lt 1 ]; then
    echo Cannot find any Jellyfish indexes!
    exit 1
fi

while read FASTA; do
  #
  # Find our target Jellyfish files
  #
  FASTA_BASE=$(basename $FASTA)
  KMER_FILE="$KMER_DIR/${FASTA_BASE}.kmers"
  LOC_FILE="$KMER_DIR/${FASTA_BASE}.loc"

  echo Kmerizing \"$FASTA_BASE\" 

  $SCRIPT_DIR/kmerizer.pl -q -i "$FASTA" -o "$KMER_FILE" \
    -l "$LOC_FILE" -k "$MER_SIZE" 

  if [[ ! -e $KMER_FILE ]]; then
    echo Cannot find K-mer file \"$KMER_FILE\"
    exit 1
  fi

  #
  # The "host" file is what will be created in the querying 
  # and will be passed to the "screen-host.pl" script 
  #
  PROG=$(basename $0 ".sh")
  TMPDIR="$DATA_DIR/tmp"
  if [[ ! -d $TMPDIR ]]; then
    mkdir -p $TMPDIR
  fi

  HOST=$(mktemp --tmpdir="$TMPDIR" "${PROG}.XXXXXXX")
  touch $HOST
  echo HOST $HOST

  i=0
  while read SUFFIX; do
    let i++
    printf "%5d: Processing %s\n" $i $(basename $SUFFIX)

    #
    # Note: no "-o" output file as we only care about the $HOST file
    #
    $JELLYFISH query -i "$SUFFIX" < "$KMER_FILE" | \
      $SCRIPT_DIR/jellyfish-reduce.pl -l "$LOC_FILE" -u $HOST --mode-min 2
  done < "$SUFFIX_LIST"

  echo Done querying/reducing to \"$i\" suffix files

  echo Screening with \"$HOST\"

  $SCRIPT_DIR/screen-host.pl -h "$HOST" -o "$SCREENED_DIR" $FASTA

  echo Removing temp files
  rm "$HOST"
done < $TMP_FILES

rm "$SUFFIX_LIST"

echo Finished $(date)
