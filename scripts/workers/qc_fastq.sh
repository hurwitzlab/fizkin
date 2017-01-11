#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=cluster_only
#PBS -l select=1:ncpus=2:mem=4gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00
#PBS -M scottdaniel@email.arizona.edu
#PBS -m ea

#
# Runs QC on a set of paired-end Illumina FASTQ files
#

### SEE BOTTOM FOR COMMAND PARAMETERS!!!!

# expects:
# SCRIPT_DIR RAW_DIR BIN_DIR FILE FASTQ_DIR FASTA_DIR

# --------------------------------------------------
# R is needed by the SolexaQA++ program
module load R
# --------------------------------------------------

set -u

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
while read FILE; do
  BASENAME=$(basename $FILE)
  let i++
  printf "%5d: %s\n" $i $BASENAME

  for F in $FASTQ_DIR/${BASENAME}*; do
    rm -f $F
  done

  TRIMMED_FILE=$FASTQ_DIR/${BASENAME}.trimmed
  # Analysis makes pretty graphs, dynamictrim individually crops each read to its longest contiguous segment for which quality scores are greater than a user-supplied quality cutoff (default is Q=13 so each base is at least 14)
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

  #this discards reads that are less than 52nt
  $BIN_DIR/fastx_clipper -v -l ${MIN_SEQ_LENGTH:=52} \
    -i $TRIMMED_FILE -o $CLIPPED_FILE

  if [[ ! -e $CLIPPED_FILE ]]; then
    echo Failed to create clipped file \"$CLIPPED_FILE\"
    continue
  fi

  if [[ ! -s $CLIPPED_FILE ]]; then
    echo Created zero-length clipped file \"$CLIPPED_FILE\"
    continue
  fi

#  only want to clip to high-quality fastqs here

#  FASTA=$(basename $FILE '.fastq')

#  $SCRIPT_DIR/fastq2fasta.awk $CLIPPED_FILE > "${FASTA_DIR}/${FASTA}.fa"

done < $TMP_FILES

echo Finished $(date)
#
#SolexaQA++ v3.1.1
#Released under GNU General Public License version 3
#C++ version developed by Mauro Truglio (M.Truglio@massey.ac.nz)
#Running with h=0
#
#Usage: SolexaQA++ analysis input_files [-p|probcutoff 0.05] [-h|phredcutoff 13] [-v|variance] [-m|minmax] [-s|sample 10000] [-b|bwa] [-d|directory path] [--sanger --solexa --illumina] [-t|torrent]
#
#Options:
#-p|--probcutoff     probability value (between 0 and 1) at which base-calling error is considered too high (default; p = 0.05) *or*
#-h|--phredcutoff    Phred quality score (between 0 and 41) at which base-calling error is considered too high
#-v|--variance       calculate variance statistics
#-m|--minmax         calculate minimum and maximum error probabilities for each read position of each tile
#-s|--sample         number of sequences to be sampled per tile for statistics estimates (default; s = 10000)
#-b|--bwa            use BWA trimming algorithm
#-d|--directory      path to directory where output files are saved
#--sanger            Sanger format (bypasses automatic format detection)
#--solexa            Solexa format (bypasses automatic format detection)
#--illumina          Illumina format (bypasses automatic format detection)
#-t|--torrent        Ion Torrent fastq file
#
#Usage: SolexaQA++ dynamictrim input_files [-t|torrent] [-p|probcutoff 0.05] [-h|phredcutoff 13] [-b|bwa] [-d|directory path] [--sanger --solexa --illumina] [-t|torrent]
#
#Options:
#-p|--probcutoff     probability value (between 0 and 1) at which base-calling error is considered too high (default; p = 0.05) *or*
#-h|--phredcutoff    Phred quality score (between 0 and 41) at which base-calling error is considered too high
#-b|--bwa            use BWA trimming algorithm
#-d|--directory      path to directory where output files are saved
#--sanger            Sanger format (bypasses automatic format detection)
#--solexa            Solexa format (bypasses automatic format detection)
#--illumina          Illumina format (bypasses automatic format detection)
#-a|--anchor         Reads will only be trimmed from the 3′ end
#-t|--torrent        Ion Torrent fastq file
#
#usage: fastx_clipper [-h] [-a ADAPTER] [-D] [-l N] [-n] [-d N] [-c] [-C] [-o] [-v] [-z] [-i INFILE] [-o OUTFILE]
#Part of FASTX Toolkit 0.0.14 by A. Gordon (assafgordon@gmail.com)
#
#[-h]         = This helpful help screen.
#[-a ADAPTER] = ADAPTER string. default is CCTTAAGG (dummy adapter).
#[-l N]       = discard sequences shorter than N nucleotides. default is 5.
#[-d N]       = Keep the adapter and N bases after it.
#(using '-d 0' is the same as not using '-d' at all. which is the default).
#[-c]         = Discard non-clipped sequences (i.e. - keep only sequences which contained the adapter).
#[-C]         = Discard clipped sequences (i.e. - keep only sequences which did not contained the adapter).
#[-k]         = Report Adapter-Only sequences.
#[-n]         = keep sequences with unknown (N) nucleotides. default is to discard such sequences.
#[-v]         = Verbose - report number of sequences.
#If [-o] is specified,  report will be printed to STDOUT.
#If [-o] is not specified (and output goes to STDOUT),
#           report will be printed to STDERR.
#[-z]         = Compress output with GZIP.
#[-D]    = DEBUG output.
#[-M N]       = require minimum adapter alignment length of N.
#If less than N nucleotides aligned with the adapter - don't clip it.   [-i INFILE]  = FASTA/Q input file. default is STDIN.
#[-o OUTFILE] = FASTA/Q output file. default is STDOUT.
#
