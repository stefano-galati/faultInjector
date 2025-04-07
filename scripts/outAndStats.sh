#!/bin/bash

if [[ $# -ne 4 ]]
then
	echo "Wrong number of arguments. Usage ./outAndStats ID OUTFOLDER OUTFILE REGMASKSFILE"
	exit 1
fi

ID=$1
OUTFOLDER=$2
OUTFILE=$3
REGMASKSFILE=$4

#wcOut=$(ls -l outputs | wc)
#nOuts=$(echo $wcOut | cut -d " " -f1) 

#echo $nOuts elements in the outputs folder
#nOuts will always be nElements+1

cp -r m5out $OUTFOLDER/$ID
cp $OUTFILE $OUTFOLDER/$ID/$OUTFILE
cp $REGMASKSFILE $OUTFOLDER/$ID/$REGMASKSFILE

exit 0
