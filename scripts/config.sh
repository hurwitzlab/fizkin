#!/bin/bash

export BIN_DIR="/rsgrps/bhurwitz/hurwitzlab/bin"
export JELLYFISH="$BIN_DIR/jellyfish"

export BASE_DIR="/rsgrps/bhurwitz/kyclark/human"
export SCRIPT_DIR="$BASE_DIR/scripts/workers"
export FASTQ_DIR="$BASE_DIR/data/fastq"
export FASTA_DIR="$BASE_DIR/data/fasta"
export SUFFIX_DIR="$BASE_DIR/data/suffix"
export KMER_DIR="$BASE_DIR/data/kmer"
export JELLYFISH_DIR="$BASE_DIR/data/jellyfish"
export HOST_JELLYFISH_DIR="$BASE_DIR/data/human"
export COUNT_DIR="$BASE_DIR/data/counts"

#export RAW_DIR="/rsgrps/bhurwitz/hurwitzlab/data/raw/Doetschman_20111007/L008/Project_RNA_1/Sample_RNA_1"
export RAW_DIR="/rsgrps/bhurwitz/kyclark/human/data/dna"
export HOST_DIR="/rsgrps/bhurwitz/hurwitzlab/data/reference/human_genome"

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
