#!/bin/bash

#PBS -q standard
#PBS -l jobtype=cluster_only
#PBS -l select=1:ncpus=4:mem=10gb
#PBS -l pvmem=20gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

source /usr/share/Modules/init/bash

set -u

COMMON="$SCRIPT_DIR/common.sh"

if [ -e $COMMON ]; then
  . "$COMMON"
else
  echo Missing common \"$COMMON\"
  exit 1
fi

echo Started $(date)

echo Host $(hostname)

if [ -z $SCRIPT_DIR ]; then
  echo Missing SCRIPT_DIR
  exit 1
fi

KMERIZER="$SCRIPT_DIR/kmerizer.pl"
if [[ ! -e $KMERIZER ]]; then
  echo Cannot find kmerizer \"$KMERIZER\"
  exit 1
fi

THREADS=16
HASH_SIZE="100M"
TMP_FILES=$(mktemp)

if [[ ${INPUT_GROUP_FILE:=""} != "" ]] && [[ ${PBS_ARRAY_INDEX:=1} -gt 0 ]]
then
  awk -F"\t" "\$1 == $PBS_ARRAY_INDEX {print \$2}" $INPUT_GROUP_FILE \
    > $TMP_FILES
else
  get_lines $FILES_LIST $TMP_FILES ${PBS_ARRAY_INDEX:=1} $STEP_SIZE
fi

NUM_FILES=$(lc $TMP_FILES)

echo Processing \"$NUM_FILES\" input files

#
# Need to make sure none of these files are too large
#
TMP_CHECKED=$(mktemp)
MAX_MB=${MAX_JELLYFISH_INPUT_SIZE:-0}

if [ $MAX_MB -gt 0 ]; then
  echo MAX_JELLYFISH_INPUT_SIZE \"$MAX_JELLYFISH_INPUT_SIZE\"
  while read FILE; do
    SIZE=$(du -m "$FILE" | cut -f 1)

    if [ $SIZE -ge $MAX_MB ]; then
      echo Splitting $(basename $FILE) size = \"$SIZE\"
      $SCRIPT_DIR/fasta-split.pl -m $MAX_MB -f $FILE -o $FASTA_SPLIT_DIR

      BASENAME=$(basename $FILE)
      BASENAME=${BASENAME%.*}
      find $FASTA_SPLIT_DIR -name $BASENAME\* -type f >> $TMP_CHECKED
    else
      echo $FILE >> $TMP_CHECKED
    fi
  done < $TMP_FILES

  cp $TMP_CHECKED $TMP_FILES
  rm $TMP_CHECKED
  NUM_FILES=$(lc $TMP_FILES)

  echo After checking to split, we have \"$NUM_FILES\" files
fi

i=0
while read FILE; do
  BASENAME=$(basename $FILE)
  JF_FILE="$OUT_DIR/$BASENAME"
  KMER_FILE="$KMER_DIR/${BASENAME}.kmer"
  LOC_FILE="$KMER_DIR/${BASENAME}.loc"

  let i++
  printf "%5d: %s\n" $i $BASENAME

  OUT_COUNTER_LEN=""
  if [ ${JELLYFISH_OUT_COUNTER_LEN:=""} != "" ]; then
    OUT_COUNTER_LEN="--out-counter-len=$JELLYFISH_OUT_COUNTER_LEN"
  fi

  if [[ ! -e "$JF_FILE" ]]; then
    # 
    # Method 1: straight-up count
    # 
    #$JELLYFISH count $OUT_COUNTER_LEN -m $MER_SIZE -s $HASH_SIZE \
    #  -t $THREADS -o $JF_FILE $FILE

    # 
    # Method 2: Bloom counter
    # 
    #BLOOM_COUNTER=$FILE.bc
    #time $JELLYFISH bc -m $MER_SIZE -s $HASH_SIZE -t $THREADS -o $BLOOM_COUNTER $FILE
    #time $JELLYFISH count $OUT_COUNTER_LEN -m $MER_SIZE -s $HASH_SIZE -t $THREADS --bc $BLOOM_COUNTER -o $JF_FILE $FILE
    #rm $BLOOM_COUNTER

    # 
    # Method 3: Bloom filter; fastest, small size
    # 
    $JELLYFISH count $OUT_COUNTER_LEN -m $MER_SIZE -s $HASH_SIZE -t $THREADS \
      --bf-size $HASH_SIZE -o $JF_FILE $FILE
  fi

  if [[ ! -e $KMER_FILE ]]; then
    $KMERIZER -q -i "$FILE" -o "$KMER_FILE" -l "$LOC_FILE" -k "$MER_SIZE"
  fi
done < $TMP_FILES

echo Finished $(date)
