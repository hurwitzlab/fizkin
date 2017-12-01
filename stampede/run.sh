#!/bin/bash

#SBATCH -J fizkin
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -p normal
#SBATCH -t 24:00:00
#SBATCH -A iPlant-Collabs

set -u

ALIAS_FILE=""
EUC_DIST_PERCENT=0.1
HASH_SIZE="100M"
IN_DIR=""
IMG="fizkin.img"
SINGULARITY_EXEC="singularity exec $IMG"
JELLYFISH="$SINGULARITY_EXEC jellyfish"
KMER_SIZE="20"
MAX_SEQS=500000
MIN_MODE=1
METADATA_FILE=""
NUM_SCANS=20000
OUT_DIR="$PWD/fizkin-out"
QUERY=""
SAMPLE_DIST=1000
THREADS=12

export LAUNCHER_DIR="$HOME/src/launcher"
export LAUNCHER_PLUGIN_DIR="$LAUNCHER_DIR/plugins"
export LAUNCHER_WORKDIR="$PWD"
export LAUNCHER_RMI="SLURM"
export LAUNCHER_SCHED="interleaved"

function lc() {
    FILE=$1
    [[ -f "$FILE" ]] && wc -l "$FILE" | cut -d ' ' -f 1
}

function HELP() {
    printf "Usage:\n  %s -i IN_DIR \n\n" "$(basename "$0")"
  
    echo "Required arguments:"
    echo " -i IN_DIR (input directory)"
    echo ""
    echo " OR"
    echo ""
    echo " -q QUERY (dirs/files)"
    echo ""
    echo "Optional arguments:"
    echo " -a ALIAS_FILE"
    echo " -d SAMPLE_DIST ($SAMPLE_DIST)"
    echo " -e EUC_DIST_PERCENT ($EUC_DIST_PERCENT)"
    echo " -k KMER_SIZE ($KMER_SIZE)"
    echo " -m METADATA_FILE"
    echo " -M MIN_MODE ($MIN_MODE)"
    echo " -n NUM_SCANS ($NUM_SCANS)"
    echo " -o OUT_DIR ($OUT_DIR)"
    echo " -s HASH_SIZE ($HASH_SIZE)"
    echo " -t THREADS ($THREADS)"
    echo " -x MAX_SEQS ($MAX_SEQS)"
    exit 0
}

[[ $# -eq 0 ]] && HELP

while getopts :a:d:e:i:k:m:M:n:o:q:s:t:x:h OPT; do
    case $OPT in
      a)
          ALIAS_FILE="$OPTARG"
          ;;
      d)
          SAMPLE_DIST="$OPTARG"
          ;;
      e)
          EUC_DIST_PERCENT="$OPTARG"
          ;;
      h)
          HELP
          ;;
      i)
          IN_DIR="$OPTARG"
          ;;
      k)
          KMER_SIZE="$OPTARG"
          ;;
      m)
          METADATA_FILE="$OPTARG"
          ;;
      M)
          MIN_MODE="$OPTARG"
          ;;
      n)
          NUM_SCANS="$OPTARG"
          ;;
      o)
          OUT_DIR="$OPTARG"
          ;;
      q)
          QUERY="$QUERY $OPTARG"
          ;;
      s)
          HASH_SIZE="$OPTARG"
          ;;
      t)
          THREADS="$OPTARG"
          ;;
      x)
          MAX_SEQS="$OPTARG"
          ;;
      :)
          echo "Error: Option -$OPTARG requires an argument."
          exit 1
          ;;
      \?)
          echo "Error: Invalid option: -${OPTARG:-""}"
          exit 1
    esac
done

# --------------------------------------------------
#
# 0. Check input, set up
#
echo "Started $(date)"

INPUT_FILES=$(mktemp)
if [[ -n "$IN_DIR" ]]; then
    if [[ -d "$IN_DIR" ]]; then
        find "$IN_DIR" -type f > "$INPUT_FILES"
    else
        echo "IN_DIR \"$IN_DIR\" is not a directory"
        exit 1
    fi
elif [[ -n "$QUERY" ]]; then
    for QRY in $QUERY; do
        if [[ -f "$QRY" ]]; then
            echo "$QRY" >> "$INPUT_FILES"
        elif [[ -d "$QRY" ]]; then
            find "$QRY" -type f -size +0c >> "$INPUT_FILES"
        else
            echo "\"$QRY\" is neither file nor directory"
        fi
    done
fi

if [[ $MIN_MODE -lt 1 ]]; then
    echo "MIN_MODE \"$MIN_MODE\" must be greater than zero"
    exit 1
fi

NUM_FILES=$(lc "$INPUT_FILES")
if [[ $NUM_FILES -lt 1 ]]; then
    echo "Found no input files in QUERY/IN_DIR"
    exit 1
fi

[[ ! -d "$OUT_DIR" ]] && mkdir -p "$OUT_DIR"


# --------------------------------------------------
#
# 1. Subset files
#
if [[ $MAX_SEQS -gt 0 ]]; then
    echo "Will subset NUM_FILES \"$NUM_FILES\" to MAX_SEQS \"$MAX_SEQS\""

    SUBSET_DIR="$OUT_DIR/subset"
    [[ ! -d "$SUBSET_DIR" ]] && mkdir -p "$SUBSET_DIR"

    SUBSET_PARAM="$$.subset.param"
    i=0
    while read -r FILE; do
        let i++
        BASENAME=$(basename "$FILE")
        printf "%3d: %s\n" $i "$BASENAME"

        SUBSET_FILE="$SUBSET_DIR/$BASENAME"
        if [[ -s "$SUBSET_FILE" ]]; then
            echo "SUBSET_FILE \"$SUBSET_FILE\" exists, skipping"
        else
            echo "$SINGULARITY_EXEC fa_subset.py -o $SUBSET_DIR -n $MAX_SEQS $FILE" >> "$SUBSET_PARAM"
        fi
    done < "$INPUT_FILES"

    NJOBS=$(lc "$SUBSET_PARAM")

    if [[ $NJOBS -lt 1 ]]; then
        echo "No subset launcher jobs to run!"
    else
        export LAUNCHER_JOB_FILE="$SUBSET_PARAM"
        [[ $NJOBS -ge 16 ]] && export LAUNCHER_PPN=16
        echo "Starting NJOBS \"$NJOBS\" $(date)"
        "$LAUNCHER_DIR/paramrun"
        echo "Ended LAUNCHER $(date)"
        rm "$SUBSET_PARAM"
    fi

    SUBSET_FILES=$(mktemp)
    find "$SUBSET_DIR" -type f -size +0c > "$SUBSET_FILES"
else
    echo "No MAX_SEQS, so using INPUT_FILES"
    SUBSET_FILES="$INPUT_FILES"
fi

NUM_SUBSET=$(lc "$SUBSET_FILES")

echo "Created NUM_SUBSET \"$NUM_SUBSET\""

if [[ $NUM_SUBSET -lt 1 ]]; then
    echo "Something bad happened with subset, exiting."
    exit 1
fi

# --------------------------------------------------
#
# 2. Index with Jellyfish
#
JF_DIR="$OUT_DIR/jf"
[[ ! -d "$JF_DIR" ]] && mkdir -p "$JF_DIR"

COUNT_CMD="$JELLYFISH count -m $KMER_SIZE -t $THREADS -s $HASH_SIZE"
COUNT_PARAM="$$.count.param"

i=0
while read -r FILE; do
    let i++
    BASENAME=$(basename "$FILE")
    printf "%3d: %s\n" $i "$BASENAME"
    
    JF_FILE="$JF_DIR/$BASENAME"
    if [[ -s "$JF_FILE" ]]; then
        echo "Index exists for \"$BASENAME,\" skipping"
    else 
        echo "$COUNT_CMD -o $JF_FILE $FILE" >> "$COUNT_PARAM"
    fi
done < "$SUBSET_FILES"

NJOBS=$(lc "$COUNT_PARAM")

if [[ $NJOBS -lt 1 ]]; then
    echo "No counting launcher jobs to run!"
else
    export LAUNCHER_JOB_FILE="$COUNT_PARAM"
    [[ $NJOBS -ge 16 ]] && export LAUNCHER_PPN=16
    echo "Starting NJOBS \"$NJOBS\" $(date)"
    "$LAUNCHER_DIR/paramrun"
    echo "Ended LAUNCHER $(date)"
    rm "$COUNT_PARAM"
fi

JF_INDEXES=$(mktemp)
find "$JF_DIR" -type f -size +0c > "$JF_INDEXES"
NUM_JF=$(lc "$JF_INDEXES")

if [[ $NUM_JF -lt 1 ]]; then
    echo "Found no Jellyfish indexes in JF_DIR \"$JF_DIR\". Stopping"
    exit 1
fi

# --------------------------------------------------
#
# 3. Compare all subset files to JF indexes
#
echo "Will process NUM_JF \"$NUM_JF\" files"

QUERY_PARAM="$$.query.param"
QUERY_CMD="$SINGULARITY_EXEC query_per_sequence $MIN_MODE"
QUERY_DIR="$OUT_DIR/query"
i=0
while read -r FASTA; do
    FA_BASENAME=$(basename "$FASTA")
    QRY_DIR="$QUERY_DIR/$FA_BASENAME"
    [[ ! -d "$QRY_DIR" ]] && mkdir -p "$QRY_DIR"

    while read -r INDEX; do
        let i++
        INDEX_BASENAME=$(basename "$INDEX")
        printf "%3d: %s -> %s\n" $i "$FA_BASENAME" "$INDEX_BASENAME"
        QUERY_OUT="$QRY_DIR/$INDEX_BASENAME"
        if [[ -f "$QUERY_OUT" ]]; then
            echo "\"$QUERY_OUT\" exists, skipping"
        else
            echo "$QUERY_CMD $INDEX $FASTA > $QUERY_OUT" >> "$QUERY_PARAM"
        fi
    done < "$JF_INDEXES"
done < "$SUBSET_FILES"

NJOBS=$(lc "$QUERY_PARAM")

if [[ $NJOBS -lt 1 ]]; then
    echo "No query launcher jobs to run"
else
    export LAUNCHER_JOB_FILE="$QUERY_PARAM"
    [[ $NJOBS -ge 16 ]] && export LAUNCHER_PPN=16
    echo "Starting NJOBS \"$NJOBS\" $(date)"
    "$LAUNCHER_DIR/paramrun"
    echo "Ended LAUNCHER $(date)"
    rm "$QUERY_PARAM"
fi

# --------------------------------------------------
#
# 4. Count the number of reads for each comparison
#
QUERIES=$(mktemp)
find "$QUERY_DIR" -type f > "$QUERIES"
NUM_QUERIES=$(lc "$QUERIES")

if [[ $NUM_QUERIES -lt 1 ]]; then
    echo "Found no files in QUERY_DIR \"$QUERY_DIR\""
    exit 1
fi

echo "Counting NUM_QUERIES \"$NUM_QUERIES\""

MODE_DIR="$OUT_DIR/mode"
while read -r QRY_FILE; do
    BASENAME=$(basename "$QRY_FILE")
    BASE_DIR=$(basename "$(dirname "$QRY_FILE")")
    MODE_OUT_DIR="$MODE_DIR/$BASE_DIR"
    [[ ! -d "$MODE_OUT_DIR" ]] && mkdir -p "$MODE_OUT_DIR"

    MODE_FILE="$MODE_OUT_DIR/$BASENAME"
    if [[ ! -f "$MODE_FILE" ]]; then
        wc -l "$QRY_FILE" | awk '{print $1}' > "$MODE_FILE"
    fi
done < "$QUERIES"
rm "$QUERIES"

# --------------------------------------------------
#
# 5. Make the raw/normalized matrices from the mode counts
#
SNA_DIR="$OUT_DIR/sna"
[[ ! -d "$SNA_DIR" ]] && mkdir -p "$SNA_DIR"

$SINGULARITY_EXEC make_matrix.py -m "$MODE_DIR" -o "$SNA_DIR"

MATRIX_RAW="$SNA_DIR/matrix_raw.txt"
if [[ ! -f "$MATRIX_RAW" ]]; then
    echo "Failed to create MATRIX_RAW \"$MATRIX_RAW\""
    exit 1
fi

MATRIX_NORM="$SNA_DIR/matrix_normalized.txt"
if [[ ! -f "$MATRIX_NORM" ]]; then
    echo "Failed to create MATRIX_NORM \"$MATRIX_NORM\""
    exit 1
fi

# --------------------------------------------------
#
# 6. Process any metadata file putting results into the "sna" 
#    dir where it will be used by the "sna.r" program
#
if [[ -n "$METADATA_FILE" ]] && [[ -f "$METADATA_FILE" ]]; then
    echo "Processing METADATA_FILE \"$METADATA_FILE\""

    META_DIR="$SNA_DIR/meta"
    [[ ! -d "$META_DIR" ]] && mkdir -p "$META_DIR"

    singularity exec "$IMG" make_metadata_dir.py \
        -f "$METADATA_FILE" \
        -o "$META_DIR" \
        --eucdistper "$EUC_DIST_PERCENT" \
        --sampledist "$SAMPLE_DIST" 
fi

# --------------------------------------------------
#
# 7. Run the SNA/GBME programs, produce visualizations.
#
ALIAS_FILE_ARG=""
[[ -n "$ALIAS_FILE" ]] && ALIAS_FILE_ARG="-a $ALIAS_FILE"

GBME_PREVIOUS="$SNA_DIR/gbme.out"
[[ -f "$GBME_PREVIOUS" ]] && rm -f "$GBME_PREVIOUS"

$SINGULARITY_EXEC sna.r -f "$MATRIX_NORM" -o "$SNA_DIR" -s "sna-gbme.pdf" -n $NUM_SCANS $ALIAS_FILE_ARG

$SINGULARITY_EXEC make_pcoa.r -f "$MATRIX_NORM" -d "$SNA_DIR"

GBME_OUT="$SNA_DIR/sna-gbme.pdf"
if [[ ! -f "$GBME_OUT" ]]; then
    echo "Failed to create GBME_OUT \"$GBME_OUT\""
    exit 1
fi

echo "Finished $(date)"
echo "See SNA_DIR \"$SNA_DIR\""
echo "Comments to Ken Youens-Clark kyclark@email.arizona.edu"
