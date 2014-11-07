#!/bin/bash

export BASE_DIR="/rsgrps/bhurwitz/kyclark/projects/tara"
export FASTA_DIR="$BASE_DIR/data/fasta"
export SUFFIX_DIR="$BASE_DIR/data/suffix"
export KMER_DIR="$BASE_DIR/data/kmer"
export JELLYFISH_DIR="$BASE_DIR/data/jellyfish"
export SCRIPT_DIR="$BASE_DIR/scripts/workers"
export COUNT_DIR="$BASE_DIR/data/counts"
export MER_SIZE=20
export BIN_DIR="/rsgrps/bhurwitz/bin"
export JELLYFISH="$BIN_DIR/jellyfish"

function create_dirs {
    for dir in $1 $2; do
        if [ -d "$dir" ]; then
            rm -rf "$dir/*"
        else
            mkdir -p "$dir"
        fi
    done
}
