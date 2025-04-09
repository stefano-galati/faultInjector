#!/bin/bash

INJECTORCONFIGFILE="injectorConfig.txt"
SCRIPTSFOLDER="scripts"
currentfolder=$(pwd)

if [[ $# -gt 1 ]]; then
	echo "Wrong number of arguments. Usage:"
	echo "./faultInjector.sh (using fault list specified in injectorConfig.txt)"
	echo "./faultInjector.sh FAULTLISTFILE"
fi

declare -A parameters
parametersString="SIMULATIONSFOLDER BINARYFILESFOLDER GEM5FOLDER GEM5CONFIGSFOLDER FAULTLISTSFOLDER CUSTOMREGMASKSFOLDER FAULTLISTFILE OUTPUTSFOLDER DATABASEFOLDER ISA GEM5 CONFIG BINARYFILE DEBUGFLAGS DEBUGFILE TICKLIMIT OUTPUTFILE OUTPUTREDFILE ERRORREDFILE OUTCORRECTFILE SUMMARYFILE REGMASKSFILE CREATEHISTOGRAM"

#initialize dictionary
for p in $parametersString
do
	parameters[$p]="no"
done

#default values
parameters[OUTCORRECTFILE]="outCorrect.txt"
parameters[SUMMARYFILE]="simRes.txt"
parameters[REGMASKSFILE]="registerMasks.txt"

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
				if [[ "$field2" != "" ]]; then
					parameters[$p]="$field2"
				fi
			fi
		done
	fi
	
done < injectorConfig.txt

#debugging echoes
for p in $parametersString
do
	echo "$p -> ${parameters[$p]}"
done


#TODO if database folder not specified, don't copy outputs
mandatoryParams="SIMULATIONSFOLDER  BINARYFILESFOLDER GEM5FOLDER GEM5CONFIGSFOLDER FAULTLISTSFOLDER CUSTOMREGMASKSFOLDER OUTPUTSFOLDER ISA CONFIG BINARYFILE OUTPUTFILE"
folderParams="SIMULATIONSFOLDER CUSTOMREGMASKSFOLDER BINARYFILESFOLDER GEM5FOLDER GEM5CONFIGSFOLDER FAULTLISTSFOLDER OUTPUTSFOLDER DATABASEFOLDER"

#check if parameter is present
for p in $mandatoryParams
do
	if [[ ${parameters[$p]} == "no" ]]; then
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

simulationsfolder=${parameters[SIMULATIONSFOLDER]}
binaryfilesfolder=${parameters[BINARYFILESFOLDER]}
gem5folder=${parameters[GEM5FOLDER]}
gem5configsfolder=${parameters[GEM5CONFIGSFOLDER]}
faultlistsfolder=${parameters[FAULTLISTSFOLDER]}
faultlistfile=${parameters[FAULTLISTFILE]}
faultlistpath=$faultlistsfolder/$faultlistfile
outputsfolder=${parameters[OUTPUTSFOLDER]}
databasefolder=${parameters[DATABASEFOLDER]}
isa=${parameters[ISA]}
gem5="$gem5folder/build/$isa/${parameters[GEM5]}"
config=$gem5configsfolder/${parameters[CONFIG]}
binaryfile=$binaryfilesfolder/${parameters[BINARYFILE]}
debugflags=${parameters[DEBUGFLAGS]}
debugfile=${parameters[DEBUGFILE]}
ticklimit=${parameters[TICKLIMIT]}
outputfile=${parameters[OUTPUTFILE]}
errorredfile=${parameters[ERRORREDFILE]}
outputredfile=${parameters[OUTPUTREDFILE]}
outcorrectfile=${parameters[OUTCORRECTFILE]}
summaryfile=${parameters[SUMMARYFILE]}
regmasksfile=${parameters[REGMASKSFILE]}
createhistogram=${parameters[CREATEHISTOGRAM]}
customregmasksfolder=${parameters[CUSTOMREGMASKSFOLDER]}


#check if files exist
if ! [[ -f $gem5 ]]; then
	"$gem5 does not exist"
fi
if ! [[ -f $config ]]; then
	"$config does not exist"
fi
if ! [[ -f $faultlistpath ]]; then
	"$faultlistpath does not exist"
fi
if ! [[ -f $binaryfile ]]; then
	"$binaryfile does not exist"
fi

#BEGINNING OF EXECUTIONS

#GOLDEN EXECUTION

cd $simulationsfolder 
#-------------------------------------------------------------------------------------------------------------

#remove old outputs
rm -rf outputs/*

#create files
rm -f "$regmasksfile"
touch "$regmasksfile"	#empty regmasks file
rm -f "$outputfile"
touch "$outputfile"
rm -f "$summaryfile"
touch "$summaryfile"

#run gem5 with empty regmasks file
$currentfolder/$SCRIPTSFOLDER/gem5Execution.sh $gem5 $config $binaryfile $debugflags $debugfile $outputredfile $errorredfile no no

status=$?
echo $status
if [[ $status == "255" ]] || [[ $status == "1" ]]; then	#TODO CHANGE RETURN VALUE OF INFINITE LOOP. 1 USED FOR GENERIC ERROR
	echo "Exiting..."
	exit 1
fi

let goldenTicks=$(cat ./m5out/stats.txt | grep simTicks | head -n 1 | tr -s " " | cut -d " " -f2)
cp "$outputfile" "$outcorrectfile"
#-------------------------------------------------------------------------------------------------------------
cd $currentfolder

#check ticklimit
if [[ $ticklimit == *"%"* ]]; then
	let percentage=$(echo $ticklimit | cut -d "%" -f1)
	let ticklimit=$goldenTicks*$percentage/100
	echo
	echo "Percentage = ${percentage}% -> Tick limit = $ticklimit"
	echo
else
	echo
	echo "Tick limit = $ticklimit"
	echo
fi

#FAULTY EXECUTIONS

cd $simulationsfolder 
#-------------------------------------------------------------------------------------------------------------
#read fault list line by line
let counter=0
while read line
do	
	#if not a comment, retrieve id, regs, mask, type
	if ! [[ $line =~ ^# ]]; then
		#generate regMasks from fault list
		let counter=$counter+1
		id=$(echo $line | cut -d ';' -f1)
		regs=$(echo $line | cut -d ';' -f2)
		mask=$(echo $line | cut -d ';' -f3)
		type=$(echo $line | cut -d ';' -f4)
		
		#wrong formatting -> exit
		if [[ "$id" == "" ]] || [[ "$regs" == "" ]]; then
			echo "Error reading fault list. Each line must be formatted in one of the following ways:"
			echo "ID;REGISTERS;MASK;FAULTTYPE"
			echo "ID;CUSTOMFILE"
			exit 1
		fi
		
		if [[ "$mask" == "" ]] && [[ "$type" == "" ]]; then
			#only two parameters -> use custom file
			customFile=$customregmasksfolder/$regs
			cat $customFile > $regmasksfile
		else
			#four parameters
			if [[ "$mask" == "" ]] || [[ "$type" == "" ]]; then
				echo "Error reading fault list. Each line must be formatted in one of the following ways:"
				echo "ID;REGISTERS;MASK;FAULTTYPE"
				echo "ID;CUSTOMFILE"
				exit 1
			else
				$currentfolder/$SCRIPTSFOLDER/generateRegMasks.sh $regs $mask $type $regmasksfile
			fi
		fi
		
		#debugging echos
		echo "RegisterMasks #$counter"
		cat $regmasksfile
		echo
		
		#start execution using the current regMasks file
		$currentfolder/$SCRIPTSFOLDER/gem5Execution.sh $gem5 $config $binaryfile $debugflags $debugfile $outputredfile $errorredfile no $ticklimit
		status=$?
		echo "Status: $status"
		if [[ $status == "255" ]]; then
			echo "Exiting..."
			exit 1
		fi
		
		#classify the fault
		$currentfolder/$SCRIPTSFOLDER/classify.sh $id $outputfile $outcorrectfile $summaryfile $status
		if [[ "$?" == "1" ]]; then
			echo "Exiting..."
			exit 1
		fi
		
		#store the output files and the statistics, as well as the register masks applied
		#TODO change if output redirection is applied
		$currentfolder/$SCRIPTSFOLDER/outAndStats.sh $id $outputsfolder $outputfile $regmasksfile
		if [[ "$?" == "1" ]]; then
			echo "Exiting..."
			exit 1
		fi
	fi
done < $faultlistpath

if [[ $createhistogram = "yes" ]] || [[ $createhistogram = "YES" ]]; then
	$currentfolder/$SCRIPTSFOLDER/createHistogram.sh $summaryfile
fi

#summaryfile is already a path since we are in the simulations folder. I had to access the dictionary to avoid bringing the whole path as a name
$currentfolder/$SCRIPTSFOLDER/storeInDB.sh  $outputsfolder $databasefolder $faultlistsfolder $faultlistfile $summaryfile
if [[ "$?" == "1" ]]; then
	echo "Exiting..."
	exit 1
fi

#-------------------------------------------------------------------------------------------------------------
cd $currentfolder

echo
echo "Bye bye"

