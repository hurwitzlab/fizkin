#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=1:mem=2gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

source /usr/share/Modules/init/bash

/rsgrps1/mbsulli/bioinfo/biotools/bin/gt suffixerator -dna -pl -tis -suf -lcp -parts 4 -db $FILE_PATH -indexname $FINAL_DIR/$IN.reads

/rsgrps1/mbsulli/bioinfo/biotools/bin/gt tallymer mkindex -mersize $MER_SIZE -minocc 1 -indexname $FINAL_DIR/$FILE.tyr-reads -counts -pl -esa $FINAL_DIR/$FILE.reads

