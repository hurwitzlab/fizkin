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
export EMAIL="kyclark@email.arizona.edu"
export GROUP="mbsulli"

#
# The main checkout
#
PROJECT_DIR="/rsgrps/bhurwitz/kyclark/mouse"

#
# Where we can find the worker scripts
#
export SCRIPT_DIR="$PROJECT_DIR/scripts/workers"

#
# Where to put all our generated data
#
export DATA_DIR="$PROJECT_DIR/data"

# Where to find the "raw" DNA or RNA reads
#
export RAW_DIR="/rsgrps/bhurwitz/hurwitzlab/data/raw/Doetschman_20111007/all"

#
# Where to find the host genome for screening
#
export HOST_DIR="/rsgrps/bhurwitz/hurwitzlab/data/reference/mouse_genome/20141111 /rsgrps/bhurwitz/hurwitzlab/data/reference/soybean /rsgrps/bhurwitz/hurwitzlab/data/reference/yeast /rsgrps/bhurwitz/hurwitzlab/data/reference/wheat /rsgrps/bhurwitz/hurwitzlab/data/reference/medicago /rsgrps/bhurwitz/hurwitzlab/data/reference/zea_mays/v3"

#
# Where to put the results of our steps
#
export HOST_JELLYFISH_DIR="$DATA_DIR/jellyfish/host"

export HOST_BOWTIE_DIR="/rsgrps/bhurwitz/hurwitzlab/data/bowtie"

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
export BT_ALIGNED_DIR="$DATA_DIR/bowtie-aligned"
export SCREENED_DIR="$DATA_DIR/screened"
# "Rejected" directory is for reads that match hosts, i.e. where the mouse RNA kmers are going to go
export REJECTED_DIR="$DATA_DIR/rejected"
export SUFFIX_DIR="$DATA_DIR/suffix"
export KMER_DIR="$DATA_DIR/kmer"
export JELLYFISH_DIR="$DATA_DIR/jellyfish"
export FASTA_SPLIT_DIR="$DATA_DIR/fasta-split"
export COUNT_DIR="$DATA_DIR/counts"
export MODE_DIR="$DATA_DIR/modes"
export MATRIX_DIR="$DATA_DIR/matrix"
export MAX_JELLYFISH_INPUT_SIZE=800 # MB

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
