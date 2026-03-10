#!/bin/bash

if [[ $# -lt 10 ]]; then
	echo "$#"
	echo "Wrong number of parameters. Usage gem5Execution.sh GEM5 CONFIG BINARYFILE DEBUGFLAGS DEBUGFILE OUTPUTFILE ERRORFILE SHOWARGS TICKLIMIT FAULTLOGS"
	exit -1
fi

GEM5=$1
CONFIG=$2
BINARYFILE=$3
DEBUGFLAGS=$4
DEBUGFILE=$5
OUTPUTFILE=$6
ERRORFILE=$7
SHOWARGS=$8
TICKLIMIT=$9
FAULTLOGS=${10}

# IMPORTANT:
# SPECIFY THE ISA BEFORE ANY OTHER VARIABLE

rm -rf m5out/*

#print values
if [[ $SHOWARGS == "true" ]]
then
	echo "GEM5 = $GEM5"
	echo "CONFIG = $CONFIG"
	echo "BINARYFILE =$BINARYFILE"
	echo "DEBUGFLAGS = $DEBUGFLAGS"
	echo "DEBUGFILE = $DEBUGFILE"
	echo "OUTPUTFILE = $OUTPUTFILE"
	echo "ERRORFILE = $ERRORFILE" 
	echo "FAULTLOGS = $FAULTLOGS"
fi

#build command
command="$GEM5"

if [[ $DEBUGFLAGS != "no" ]]
then
	command="$command --debug-flags $DEBUGFLAGS"

	if [[ $DEBUGFILE != "no" ]]
	then
		command="$command --debug-file=$DEBUGFILE"
	fi
fi

if [[ $OUTPUTFILE != "no" ]]
then
	command="$command -r --stdout-file=$OUTPUTFILE"
fi

if [[ $ERRORFILE != "no" ]]
then
	command="$command -e --stderr-file=$ERRORFILE"
fi

if [[ $TICKLIMIT != "no" ]]
then
	CONFIG="$CONFIG --tick_limit $TICKLIMIT"
fi

if [[ $FAULTLOGS != "no" ]]
then
	command="$command --debug-flags=FaultLogs --debug-file=faultLogs.txt"
fi

command="$command $CONFIG $BINARYFILE"
echo "Final command: $command"
echo ""

#execute command
eval $command

status="$?"

#./outAndStats.sh
echo "$status"

exit $status
