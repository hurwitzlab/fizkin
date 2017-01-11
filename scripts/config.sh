#!/bin/bash

# --------------------------------------------------
#
# config.sh
#
# Edit this file to match your directory structure
#
# --------------------------------------------------

#
# Some constants
#
export MER_SIZE=20
export MIN_SEQ_LENGTH=50
export QSTAT="/usr/local/bin/qstat_local"
export GUNZIP="/bin/gunzip"
export EMAIL="scottdaniel@email.arizona.edu"
export GROUP="bhurwitz"

#
# The main checkout
#
PRJ_DIR="/rsgrps/bhurwitz/scottdaniel/mouse"

#
# Where we can find the worker scripts
#
export SCRIPT_DIR="$PRJ_DIR/scripts/workers"

#
# Where to put all our generated data
#
export DATA_DIR="$PRJ_DIR/data"

# Where to find the "raw" DNA or RNA reads
#
export RAW_DIR="/rsgrps/bhurwitz/hurwitzlab/data/raw/Doetschman_20111007/all"
#
# Where to put the results of our steps
#
#after QC, trimming and discarding
export FASTQ_DIR="$DATA_DIR/clipped"
#after sorting and merging
export READY_DIR="$DATA_DIR/fastq_out"
#
# Some custom functions for our scripts
#
# --------------------------------------------------
function init_dir {
    for dir in $*; do
        if [ -d "$dir" ]; then
            rm -rf $dir/*
        else
            mkdir -p "$dir"
        fi
    done
}

# --------------------------------------------------
function lc() {
  FILE=${1:-''}
  if [ -e $FILE ]; then
    wc -l $FILE | cut -d ' ' -f 1
  else 
    echo 0
  fi
}
