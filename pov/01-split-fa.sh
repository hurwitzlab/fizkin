#!/bin/bash

source ./config.sh

# [Shiran] If you're not forking a shell, you don't need to export vars into
# the environment. Unless they're used by qsub
export JOBS=10
export CWD="$PWD"

# [Shiran] Any time a path var is being used, it can screw things up royally if
# there's a space, so each such var should be enclosed by double-quotes.
PROG=`basename "$0" ".sh"`
ERR_DIR="$CWD/err/$PROG"
OUT_DIR="$CWD/out/$PROG"

create_dirs "$ERR_DIR" "$OUT_DIR"

cd "$FASTA_DIR"

#
# Split each FASTA file
#
i=0

# [Shiran] This form also handles file paths with spaces:
ls *.fa | while read file; do
    i=$((i+1))

    # [Shiran] export needed?
    export FILE=`basename "$file"`

    printf '%03d: %40s' $i "$FILE"

    FIRST=`qsub -v BIN_DIR,FILE,FASTA_DIR -N split_fa \
        "-e $ERR_DIR/$FILE" -o "$OUT_DIR/$FILE" "$SCRIPT_DIR/split_fa.sh"`

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
