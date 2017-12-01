#!/bin/bash

#SBATCH -A iPlant-Collabs
#SBATCH -p normal
#SBATCH -t 24:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -J fiztest
#SBATCH --mail-type BEGIN,END,FAIL
#SBATCH --mail-user kyclark@email.arizona.edu

set -u

#./run.sh -q "$WORK/data/dolphin/fasta" -o "$WORK/data/dolphin/fizkin-out"
./run.sh -x 10000 -q "$WORK/data/dolphin/fasta" -o "$WORK/data/dolphin/fizkin-out-10K"

#./run.sh -q "$WORK/data/pov/fasta" -o "$WORK/data/pov/fizkin-out" -m "$WORK/data/pov/meta.tab"
