#!/bin/bash

DATA_DIR="/rsgrps/bhurwitz/hurwitzlab/data/clean/tara"
export FASTA_DIR="$DATA_DIR/fasta"
export JELLYFISH_DIR="$DATA_DIR/jellyfish"
export BASE_DIR="/rsgrps/bhurwitz/kyclark/tara"
export SCRIPT_DIR="$BASE_DIR/scripts/workers"
export COUNT_DIR="$BASE_DIR/data/counts"
export KMER_DIR="$BASE_DIR/data/kmers"
export BIN_DIR="/rsgrps/bhurwitz/hurwitzlab/bin"
export JELLYFISH="$BIN_DIR/jellyfish"
export MER_SIZE=20

function create_dirs {
    for dir in $1 $2; do
        if [ -d "$dir" ]; then
            rm -rf "$dir/*"
        else
            mkdir -p "$dir"
        fi
    done
}
