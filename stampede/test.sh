#!/bin/bash

#SBATCH -A iPlant-Collabs
#SBATCH -p development # normal
#SBATCH -t 02:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -J fiztest2
#SBATCH --mail-type BEGIN,END,FAIL
#SBATCH --mail-user kyclark@email.arizona.edu

set -u

#./run.sh -q "$WORK/data/dolphin/fasta" -o "$WORK/data/dolphin/fizkin-out"

#./run.sh -x 10000 -q "$WORK/data/dolphin/fasta" -o "$WORK/data/dolphin/fizkin-out-10K"

#./run.sh -q "$WORK/data/pov/fasta" -o "$WORK/data/pov/fizkin-out" -m "$WORK/data/pov/meta.tab"

#./run.sh -K 30 -q "$WORK/data/pov/fasta" -o "$WORK/data/pov/fizkin-out-mode-30" # -m "$WORK/data/pov/meta.tab"

#./run.sh -q "$WORK/data/mock_communities/fasta" -o "$WORK/data/mock_communities/fizkin-30"

./run.sh -q "$WORK/data/bugs/ecoli_flex/fasta" -o "$WORK/data/bugs/fizkin/ecoli_flex"

./run.sh -q "$WORK/data/bugs/ecoli_sap/fasta" -o "$WORK/data/bugs/fizkin/ecoli_sap"

./run.sh -q "$WORK/data/bugs/mssa_mrsa/fasta" -o "$WORK/data/bugs/fizkin/mssa_mrsa"

./run.sh -q "$WORK/data/bugs/sap_pyo/fasta" -o "$WORK/data/bugs/fizkin/sap_pyo"
