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
  qsub -I -N bwtiebld -j oe -o "$STDOUT_DIR" -v SRC_DIR,TARGET_DIR $SCRIPT_DIR/bowtie-build.sh
  #JOB=$(qsub -N bwtiebld -j oe -o "$STDOUT_DIR" -v SRC_DIR,TARGET_DIR $SCRIPT_DIR/bowtie-build.sh)

#  printf "%5d: %s %s\n" $i $JOB $TARGET  
  break
done 

echo Done.

#
#export FILES_LIST="$HOME/${PROG}.in"
#
#find $SOURCE_DIR -type f -name \*.fa > $FILES_LIST
#
#
#COUNT=$(lc $FILES_LIST)
#
#echo Found \"$COUNT\" files in \"$SOURCE_DIR\"
#
#if [ $COUNT -lt 1 ]; then
#  echo Nothing to do.
#  exit 1
#fi
#
#JOB=$(qsub -N jf_host -j oe -o "$STDOUT_DIR" -J 1-$COUNT -v SOURCE_DIR,MER_SIZE,FILES_LIST,JELLYFISH,OUT_DIR $SCRIPT_DIR/jellyfish-count.sh)
#
#if [ $? -eq 0 ]; then
#  echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" Aloha.
#else
#  echo -e "\nError submitting job\n$JOB\n"
#fi
