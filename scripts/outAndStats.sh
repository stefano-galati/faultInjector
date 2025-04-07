#!/bin/bash

if [[ $# -ne 2 ]]
then
	echo "Wrong number of arguments. Usage ./outAndStats OUTFILE REGMASKSFILE"
	exit 1
fi

OUTFILE=$1
REGMASKSFILE=$2

wcOut=$(ls -l outputs | wc)
nOuts=$(echo $wcOut | cut -d " " -f1) 

echo $nOuts elements in the outputs folder
#nOuts will always be nElements+1

cp -r m5out outputs/$nOuts
cp $1 outputs/$nOuts/$1
cp $2 outputs/$nOuts/$2

exit 0
