#!/bin/bash

# --------------------------------------------------
#
# 01-bowtie-buildsh
#
# Build Bowtie index
#
# --------------------------------------------------

set -u
source ./config.sh
export CWD=$PWD
export SOURCE_DIR="$HOST_DIR"
export OUT_DIR="$HOST_JELLYFISH_DIR"

PROG=$(basename "$0" ".sh")
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$STDOUT_DIR"

# --------------------------------------------------

i=0
for SRC_DIR in $SOURCE_DIR; do
  let i++
  cd $SRC_DIR
  TARGET=$(echo $SRC_DIR | sed "s/.*reference\///" | sed "s/\//-/")
  export TARGET_DIR=$HOST_BOWTIE_DIR/$TARGET

  export SRC_DIR
  JOB=$(qsub -N bwtiebld -j oe -o "$STDOUT_DIR" -v SCRIPT_DIR,SRC_DIR,TARGET_DIR $SCRIPT_DIR/bowtie-build.sh)

  printf "%5d: %s %s\n" $i $JOB $TARGET  
done 

echo Done.
