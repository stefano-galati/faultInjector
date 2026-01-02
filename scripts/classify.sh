#!/bin/bash

if [[ $# -ne 5 ]];
then
	echo "Wrong number of arguments. Usage: ./classify.sh ID OUTFILE OUTCORRECTFILE SUMMARYFILE STATUS"
	exit 1
fi

ID=$1
OUTFILE=$2		
OUTCORRECTFILE=$3	
SUMMARYFILE=$4		
STATUS=$5		
STATSFILE="m5out/stats.txt"


if [[ $STATUS -ne 0 ]];	#DUE
then
	if [[ $STATUS -eq 2 ]];
	then
		echo "$ID> DUE (infinite loop)" >> "$SUMMARYFILE"
	elif [[ $STATUS -eq 134 ]];
	then
		echo "$ID> DUE (segmentation fault)" >> "$SUMMARYFILE"
	else
		echo "$ID> DUE" >> "$SUMMARYFILE"
	fi
	
else
	#check if output is different wrt to the original one
	diff "$OUTFILE" "$OUTCORRECTFILE" > /dev/null
	if [[ "$?" -eq 0 ]];
	then
		#no differences
		echo "$ID> masked" >> "$SUMMARYFILE"
	elif [[ $? -eq 1 ]];
	then
		#different outputs
		echo "$ID> SDC" >> "$SUMMARYFILE"
	fi
fi
exit 0
