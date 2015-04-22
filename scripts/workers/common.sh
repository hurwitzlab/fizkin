# --------------------------------------------------
function lc() {
    wc -l $1 | cut -d ' ' -f 1
}

# --------------------------------------------------
function get_lines() {
  FILE=$1
  OUT_FILE=$2
  START=${3:-1}
  STEP=${4:-1}

  if [ -z $FILE ]; then
    echo No input file
    exit 1
  fi

  if [ -z $OUT_FILE ]; then
    echo No output file
    exit 1
  fi

  if [[ ! -e $FILE ]]; then
    echo Bad file \"$FILE\"
    exit 1
  fi

  LC=$(lc $FILE)

  HEAD=$((${START} + ${STEP} - 1))

  if [ $HEAD -lt $LC ]; then
    head -n $HEAD $FILE | tail -n $STEP > $OUT_FILE
  else
    TAIL=$(($LC - $START + 1))
    tail -n $TAIL $FILE > $OUT_FILE
  fi
}
