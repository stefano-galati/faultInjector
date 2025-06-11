#!/bin/bash

if [[ $# -ne 5 ]]; then
	echo "Wrong number of arguments. Usage: ./storeInDB outputsFolder databaseFolder faultListFolder faultListName simResPath"
	exit 1
fi

outfolder=$1
dbfolder=$2
faultlistfolder=$3
faultlistfile=$4
simrespath=$5

faultlistname=$(echo $faultlistfile | cut -d "." -f1)

#date=$(date +%Y%m%d)
#time=$(date +%H%M)

#foldername=$(echo "${faultlistname}_${date}_${time}")
let numFiles=$(find $dbfolder -maxdepth 1 -type d -name "${faultlistname}*" | wc -l)
let fileNumber=$numFiles+1
echo "$numFiles $fileNumber"

foldername=$(echo "${faultlistname}_${fileNumber}")

mkdir $dbfolder/$foldername

#copy outputs
cp -r $outfolder/* $dbfolder/$foldername
#copy fault list
cp $faultlistfolder/$faultlistfile $dbfolder/$foldername
#copy dictionary of faults
cp $simrespath $dbfolder/$foldername

exit 0
