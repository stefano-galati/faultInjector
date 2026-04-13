#!/bin/bash

SUPPORTEDTYPES="ST0 ST1 BITFLIP"

echo "$0 $@"

if [[ $# -ne 4 && $# -ne 6 ]]; then
	echo "Wrong number of arguments. Usage $0 regs mask type outfile"
	echo "Or $0 regs mask type outfile accessnumber faultlogsfolder"
	exit 1
fi

regs=$1
mask=$2
type=$3
regmasksfile=$4
accessnumber=$5
faultlogsfolder=$6

timeintervalsfile=faultTimeIntervals.txt

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
	
	if [[ $# -gt 4 && $type == "BITFLIP" ]]; then
		regaccesses=$(cat $faultlogsfolder/${regs}.txt | wc -l)
		
		if [[ $regaccesses -ge $accessnumber && $accessnumber -ge 0 ]]; then
			#fifth fault argument for bitflip available only if a single register is used
			
			let index=$accessnumber+1	#otherwise, with head lines start from 1, not 0
			
			timestamp=$(head -n $index $faultlogsfolder/${regs}.txt | tail -n 1)
			let nexttimestamp=$timestamp+1
				
			echo $timestamp > $timeintervalsfile
			echo $nexttimestamp >> $timeintervalsfile
		else
			echo "Access number $accessnumber does not exist"
			exit 1
		fi
	fi
fi

#generate lines to add to regMasks.txt
for i in $(seq $min $max)
do
	#reg mask type
	echo "$i $mask $type" >> $regmasksfile
done


exit 0
