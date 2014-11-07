#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=1:mem=2gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

source /usr/share/Modules/init/bash

#echo cd $CWD/$READS_DIR

#
# Subtract one 
#
READS_DIR=`printf "%02d" $(($PBS_ARRAY_INDEX-1))`

cd $CWD/$READS_DIR

OUT_DIR=$DEST_DIR/$READS_DIR

if [[ ! -d $OUT_DIR ]]; then
    mkdir $OUT_DIR
fi

#
# Read file names will be sequence IDs, e.g., "GON5MYK01BCZTK.fa"
#
for READ in *.fa; do
    READ_NAME=`basename $READ ".fa"`

    while read TYR; do
        $GT tallymer search -tyr $TYR -strand fp -output qseqnum qpos counts -q $READ >> $OUT_DIR/$READ_NAME.count
    done < $INDEX_LIST
done

#
# Removed empty (zero-length) files
#
find $OUT_DIR -size 0 -exec rm -f {} \;

SUMMARY=$OUT_DIR/modes.tab
if [ -e $SUMMARY ]; then
    rm $SUMMARY
fi

#
# Calculate mode here...
#
find $OUT_DIR -name \*.count -print0 | xargs -0 $SCRIPT_DIR/calc_mode.pl >> $SUMMARY
