#!/bin/bash

source ./config.sh

export JOBS=10
export CWD="$PWD"

PROG=`basename $0 ".sh"`
ERR_DIR=$CWD/err/$PROG
OUT_DIR=$CWD/out/$PROG

create_dirs $ERR_DIR $OUT_DIR

cd $FASTA_DIR

#
# Split each FASTA file
#
i=0
for file in `ls *.fa`; do
    i=$((i+1))

    export FILE=`basename $file`

    printf '%03d: %40s' $i $FILE

    FIRST=`qsub -v BIN_DIR,FILE,FASTA_DIR -N split_fa -e $ERR_DIR/$FILE -o $OUT_DIR/$FILE $SCRIPT_DIR/split_fa.sh`

    echo $FIRST
done

#   RUN="$FILE.02_"
#   #  2- set up the output dirs
#   SECOND=`qsub -W depend=afterok:$FIRST -v CWD,FILE,FINALDIR,SCRIPTS -N createdirs -e $CWD/err/$RUN -o $CWD/out/$RUN $SCRIPTS/run_createdirs.sh`
#
#   RUN="$FILE.03_"
#   #  3- run kmer analysis against the set of databases and parse 
#   THIRD=`qsub -W depend=afterok:$SECOND -v CWD,FILE,FADIR,SCRIPTS -N runkmer -J 1-$JOBS -e $CWD/err/$RUN -o $CWD/out/$RUN $SCRIPTS/run_vmatch.sh`
#
#   RUN="$FILE.04_"
#   ## 4- get hits from kmer analyses to dbs 
#   FOURTH=`qsub -W depend=afterok:$THIRD -v JOBS,CWD,FILE,FADIR,SCRIPTS -N postkmer -e $CWD/err/$RUN -o $CWD/out/$RUN $SCRIPTS/run_post-vmatch.sh`
#  
#done
