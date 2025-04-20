#!/bin/bash

SUPPORTEDTYPES="ST0 ST1 BITFLIP"

if [[ $# -ne 4 ]]; then
	echo "Wrong number of arguments. Usage ./generateRegMasks.sh regs mask type outfile"
	exit 1
fi

regs=$1
mask=$2
type=$3
regmasksfile=$4

#check if type is supported
if ! [[ " $SUPPORTEDTYPES " == *" $type "* ]]; then
	echo "Type $type not supported"
	exit 1
fi

#remove existent regMasks file and create a new empty one
rm -f $regmasksfile
touch $regmasksfile

#which registers?
if [[ $regs == *"-"* ]]; then
	#range of registers
	let min=$(echo $regs | cut -d "-" -f1)
	let max=$(echo $regs | cut -d "-" -f2)
else
	#single register (min=max)
	let min=$regs
	let max=$regs
fi

#generate lines to add to regMasks.txt
for i in $(seq $min $max)
do
	#reg mask type
	echo "$i $mask $type" >> $regmasksfile
done


exit 0
