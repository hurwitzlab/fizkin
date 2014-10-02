#!/bin/bash

export BASE_DIR="/rsgrps2/mbsulli/kyclark/projects/pov"
export FASTA_DIR="$BASE_DIR/data/fasta"
export SUFFIX_DIR="$BASE_DIR/data/suffix"
export SCRIPT_DIR="$BASE_DIR/scripts"
export BIN_DIR="$BASE_DIR/bin"
export COUNT_DIR="$BASE_DIR/data/counts"
export MER_SIZE=20
export GT=/rsgrps1/mbsulli/bioinfo/biotools/bin/gt

function create_dirs {
    for dir in $1 $2; do
        if [ -d $dir ]; then
            rm -rf $dir/*
        else
            mkdir -p $dir
        fi
    done
}
