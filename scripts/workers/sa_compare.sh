#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l jobtype=serial
#PBS -l select=1:ncpus=12:mem=10gb
#PBS -l place=pack:shared
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

source /usr/share/Modules/init/bash

#echo cd $CWD/$READS_DIR

cd $CWD/$READS_DIR

#
# Read file names will be sequence IDs, e.g., "GON5MYK01BCZTK.fa"
#
for READ in `ls *.fa`; do
    READ_NAME=`basename $READ ".fa"`

    for TYR in `cat $INDEX_LIST`; do
        #SAMPLE_FASTA_NAME=`basename $TYR | sed "s/\.fa.*//"`

        #echo "$READ: $TYR"

        #echo $GT tallymer search -tyr $TYR -strand fp -output qseqnum qpos counts -q $READ $DEST_DIR/$READ_NAME.count

        $GT tallymer search -tyr $TYR -strand fp -output qseqnum qpos counts -q $READ >> $DEST_DIR/$READ_NAME.count

        #$GT tallymer search -tyr $TYR -strand fp -output qseqnum qpos counts -q $READ >> $DEST_DIR2/$READ_NAME-$TYR.count

        #$GT tallymer search -tyr $TYR -strand fp -output qseqnum qpos counts -q $READ > $DEST_DIR/$SAMPLE_FASTA_NAME.count
    done
done

#
# Removed empty (zero-length) files
#
find $DEST_DIR -size 0 -exec rm -f {} \;

SUMMARY=$DEST_DIR/total.count
if [ -e $SUMMARY ]; then
    rm $SUMMARY
fi

#
# Calculate mode here...
#
find $DEST_DIR -name \*.count | xargs $SCRIPT_DIR/calc_mode.pl >> $SUMMARY
