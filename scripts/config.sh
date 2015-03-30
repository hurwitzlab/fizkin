#!/bin/bash

# --------------------------------------------------
#
# config.sh
# 
# Edit this file to match your directory structure
#
# --------------------------------------------------

export SCRIPT_DIR="/rsgrps/bhurwitz/kyclark/mouse/scripts/workers"
export BIN_DIR="/rsgrps/bhurwitz/hurwitzlab/bin"
export JELLYFISH="$BIN_DIR/jellyfish"
export RAW_DIR="/rsgrps/bhurwitz/hurwitzlab/data/raw/Doetschman_20111007/all"
export HOST_DIR="/rsgrps/bhurwitz/hurwitzlab/data/reference/mouse_genome/20141111"
export HOST_JELLYFISH_DIR="/rsgrps/bhurwitz/hurwitzlab/data/jellyfish/mouse"

export DATA_DIR="/rsgrps/bhurwitz/kyclark/mouse/data"
export FASTQ_DIR="$DATA_DIR/fastq"
export FASTA_DIR="$DATA_DIR/fasta"
export SCREENED_DIR="$DATA_DIR/screened"
export SUFFIX_DIR="$DATA_DIR/suffix"
export KMER_DIR="$DATA_DIR/kmer"
export JELLYFISH_DIR="$DATA_DIR/jellyfish"
export COUNT_DIR="$DATA_DIR/counts"
export MODE_DIR="$DATA_DIR/modes"
export MER_SIZE=20
export QSTAT="/usr/local/bin/qstat_local"
export GUNZIP="/bin/gunzip"

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

