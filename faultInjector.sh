#!/bin/bash

INJECTORCONFIGFILE="injectorConfig.txt"
REGMASKSFILE="regMasks.txt"
SCRIPTSFOLDER="./scripts"

if [[ $# -gt 1 ]]; then
	echo "Wrong number of arguments. Usage:"
	echo "./faultInjector.sh (using fault list specified in injectorConfig.txt)"
	echo "./faultInjector.sh FAULTLISTFILE"
fi

declare -A parameters
parametersString="BINARYFILESFOLDER GEM5FOLDER GEM5CONFIGSFOLDER FAULTLISTSFOLDER FAULTLISTFILE OUTPUTSFOLDER DATABASEFOLDER ISA GEM5 CONFIG BINARYFILE DEBUGFLAGS DEBUGFILE"

#reading injectorConfig.txt
while read line
do
	field1=$(echo $line | cut -d '=' -f1)
	
	#check if line was a comment
	if ! [[ $field1 =~ ^# ]]; then
		field2=$(echo $line | cut -d '=' -f2)
		
		for p in $parametersString
		do
			if [[ "$field1" == "$p" ]]
			then
				parameters[$p]="$field2"
				#echo "${parameters[$p]}"
			fi
		done
	fi
	
done < injectorConfig.txt

mandatoryParams="BINARYFILESFOLDER GEM5FOLDER GEM5CONFIGSFOLDER FAULTLISTSFOLDER OUTPUTSFOLDER DATABASEFOLDER ISA CONFIG BINARYFILE"
folderParams="BINARYFILESFOLDER GEM5FOLDER GEM5CONFIGSFOLDER FAULTLISTSFOLDER OUTPUTSFOLDER DATABASEFOLDER"
fileParams="FAULTLISTFILE GEM5 CONFIG BINARYFILE"

#check if parameter is present
for p in $mandatoryParams
do
	if [[ ${parameters[$p]} == "" ]]; then
		echo "Missing mandatory parameter $p in the configuration file"
		exit 1
	fi
done

#check if folder exists
for f in $folderParams
do
	if ! [[ -d "${parameters[$f]}" ]]; then
		echo "Directory $f=${parameters[$f]} does not exist"
		exit 1
	fi
done

binaryfilesfolder=${parameters[BINARYFILESFOLDER]}
gem5folder=${parameters[GEM5FOLDER]}
gem5configsfolder=${parameters[GEM5CONFIGSFOLDER]}
faultlistsfolder=${parameters[FAULTLISTSFOLDER]}
faultlistfile=$faultlistsfolder/${parameters[FAULTLISTFILE]}
outputsfolder=${parameters[OUTPUTSFOLDER]}
databasefolder=${parameters[DATABASEFOLDER]}
isa=${parameters[ISA]}
gem5="$gem5folder/build/$isa/${parameters[GEM5]}"
config=$gem5configsfolder/${parameters[CONFIG]}
binaryfile=$binaryfilesfolder/${parameters[BINARYFILE]}
debugflags=${parameters[DEBUGFLAGS]}
debugfile=${parameters[DEBUGFILE]}

#check if files exist
if ! [[ -f $gem5 ]]; then
	"$gem5 does not exist"
fi
if ! [[ -f $config ]]; then
	"$config does not exist"
fi
if ! [[ -f $faultlistfile ]]; then
	"$faultlistfile does not exist"
fi
if ! [[ -f $binaryfile ]]; then
	"$binaryfile does not exist"
fi


#read fault list line by line
while read line
do	
	#if not a comment
	if ! [[ $line =~ ^# ]]; then
		id=$(echo $line | cut -d ';' -f1)
		regs=$(echo $line | cut -d ';' -f2)
		mask=$(echo $line | cut -d ';' -f3)
		type=$(echo $line | cut -d ';' -f4)
		./$SCRIPTSFOLDER/generateRegMasks.sh $regs $mask $type $REGMASKSFILE
	fi
done < $faultlistfile

#generate regMasks from fault list

#use predefined regMasks
	

