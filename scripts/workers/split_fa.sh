#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=2:mem=10gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

source /usr/share/Modules/init/bash

SED=/bin/sed

cd $FASTA_DIR

#
# "foo.fa" => "foo"
#
OUT_DIR=`basename $FILE ".fa"`

#
# Clean out any old runs
#
#if [ -d $OUT_DIR ]; then
#    /bin/rm -rf $OUT_DIR/*
#else
#    /bin/mkdir $OUT_DIR
#fi

#
# Split "foo.fa" into chunks of 500KB, put files into "foo" directory
#
FASPLIT="$BIN_DIR/faSplit"
$FASPLIT about $FILE 500000 "$OUT_DIR/"

#
# Go into aforementioned "foo" directory
#
cd $OUT_DIR

#
# The split files will be named like "00.fa," "01.fa"
# Make a directory for each file, e.g., "00," "01"
# Split each "00.fa" FASTA into individual read files
# using the ID of the sequence, e.g., "GON5MYK01BD1RJ.fa"
# This seems to keep the number of read files in each 
# directory to around 2K
#
for FA_FILE in `ls *.fa`; do
    FA_DIR=`basename $FA_FILE ".fa"`

    if [[ ! -d $FA_DIR ]]; then
        mkdir $FA_DIR
    fi

    $FASPLIT byname $FA_FILE $FA_DIR/
done
