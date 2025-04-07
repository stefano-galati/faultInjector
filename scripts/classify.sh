#!/bin/bash

if [[ $# -ne 4 ]];
then
	echo "Wrong number of arguments. Usage: ./classify.sh OUTFILE OUTCORRECTFILE SUMMARYFILE STATUS"
	exit 1
fi

OUTFILE=$1		#first argument
OUTCORRECTFILE=$2	#second argument
SUMMARYFILE=$3		#third argument
STATUS=$4		#fourth argument
STATSFILE="m5out/stats.txt"

wcOut=$(ls -l outputs | wc)
id=$(echo $wcOut | cut -d " " -f1) 


if [[ $STATUS -ne 0 ]];	#DUE
then
	if [[ $STATUS -eq 1 ]];
	then
		echo "$id -> DUE (infinite loop)" >> "$SUMMARYFILE"
	fi
	if [[ $STATUS -eq 134 ]];
	then
		echo "$id -> DUE (segmentation fault)" >> "$SUMMARYFILE"
	fi
else
	#check if output is different wrt to the original one
	diff "$OUTFILE" "$OUTCORRECTFILE"
	if [[ "$?" -eq 0 ]];
	then
		#no differences
		echo "$id -> masked" >> "$SUMMARYFILE"
	elif [[ $? -eq 1 ]];
	then
		#different outputs
		echo "$id -> SDC" >> "$SUMMARYFILE"
	fi
fi
exit 0
