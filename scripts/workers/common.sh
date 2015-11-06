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

  awk "NR==$START,NR==$(($START + $STEP - 1))" $FILE > $OUT_FILE
}

# --------------------------------------------------
function readlines () {
  local N="$1"
  local line
  local rc="1"

  # Read at most N lines
  for i in $(seq 1 $N)
  do
    # Try reading a single line
    read line
    if [ $? -eq 0 ]
    then
      # Output line
      echo $line
      rc="0"
    else
      break
    fi
  done

  # Return 1 if no lines where read
  return $rc
}
