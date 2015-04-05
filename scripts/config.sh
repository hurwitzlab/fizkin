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
export QSTAT="/usr/local/bin/qstat_local"
export GUNZIP="/bin/gunzip"

#
# The main checkout
#
PROJECT_DIR="/rsgrps/bhurwitz/kyclark/pov/"

#
# Where we can find the worker scripts
#
export SCRIPT_DIR="$PROJECT_DIR/scripts/workers"

#
# Where to put all our generated data
#
export DATA_DIR="$PROJECT_DIR/data"

# 
# Where we can find all our custom binaries (e.g., jellyfish)
# 
export BIN_DIR="/rsgrps/bhurwitz/hurwitzlab/bin"
export JELLYFISH="$BIN_DIR/jellyfish"

#
# Where to put the results of our steps
#
export FASTQ_DIR="$DATA_DIR/fastq"
export FASTA_DIR="$DATA_DIR/fasta"
export SCREENED_DIR="$DATA_DIR/screened"
export SUFFIX_DIR="$DATA_DIR/suffix"
export KMER_DIR="$DATA_DIR/kmer"
export JELLYFISH_DIR="$DATA_DIR/jellyfish"
export COUNT_DIR="$DATA_DIR/counts"
export MODE_DIR="$DATA_DIR/modes"
export MATRIX_DIR="$DATA_DIR/matrix"

#
# Some custom functions for our scripts
#
# --------------------------------------------------
function init_dirs {
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
    wc -l $1 | cut -d ' ' -f 1
}
