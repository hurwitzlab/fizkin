#!/bin/bash

export SCRIPT_DIR="/rsgrps/bhurwitz/kyclark/mouse/scripts/workers"
export BIN_DIR="/rsgrps/bhurwitz/hurwitzlab/bin"
export JELLYFISH="$BIN_DIR/jellyfish"
export RAW_DIR="/rsgrps/bhurwitz/hurwitzlab/data/raw/Doetschman_20111007/all"
export HOST_DIR="/rsgrps/bhurwitz/hurwitzlab/data/reference/mouse_genome/20141111"
export HOST_JELLYFISH_DIR="/rsgrps/bhurwitz/hurwitzlab/data/jellyfish/mouse"

export BASE_DIR="/rsgrps/bhurwitz/kyclark/mouse/data"
export FASTQ_DIR="$BASE_DIR/fastq"
export FASTA_DIR="$BASE_DIR/fasta"
export SUFFIX_DIR="$BASE_DIR/suffix"
export KMER_DIR="$BASE_DIR/kmer"
export JELLYFISH_DIR="$BASE_DIR/jellyfish"
export COUNT_DIR="$BASE_DIR/counts"
export MER_SIZE=20
export QSTAT="/usr/local/bin/qstat_local"
export GUNZIP="/bin/gunzip"

function create_dirs {
    for dir in $*; do
        if [ -d "$dir" ]; then
            rm -rf "$dir/*"
        else
            mkdir -p "$dir"
        fi
    done
}
