#!/bin/bash

echo "QUERY            \"${QUERY}\""
echo "ALIAS_FILE       \"${ALIAS_FILE}\""
echo "EUC_DIST_PERCENT \"${EUC_DIST_PERCENT}\""
echo "SAMPLE_DIST      \"${SAMPLE_DIST}\""
echo "NUM_SCANS        \"${NUM_SCANS}\""
echo "METADATA_FILE    \"${METADATA_FILE}\""

sh run.sh ${QUERY} ${ALIAS_FILE} ${EUC_DIST_PERCENT} ${SAMPLE_DIST} ${NUM_SCANS} ${METADATA_FILE}
