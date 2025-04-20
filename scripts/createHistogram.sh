#!/bin/bash

if [[ $# -ne 1 ]]; then
	echo "Wrong number of arguments. Usage ./statistics.sh dictionaryFile"
	exit 1
fi

#ASSUMPTION: we are already in the simulation folder
dictionaryFile=$1

declare -A histogram
let total=0

while read line
do
	result=$(echo $line | cut -d ">" -f2 | xargs)	#xargs removes leading and trailing spaces
	#echo "$result"
	if ! [[ -v histogram["$result"] ]]; then
		histogram["$result"]=1
	else
		tmp=${histogram["$result"]}
		let tmp=$tmp+1
		histogram["$result"]=$tmp
	fi
	
	let total=$total+1
	
done < $dictionaryFile

echo
echo "-----------------------------"
echo 
echo "Histogram"
echo "|||||||||"
echo "vvvvvvvvv"
echo

for key in "${!histogram[@]}"
do
	percentage="$(echo "scale=2;${histogram[$key]}/$total*100" | bc )"
	printf "%-40s %-10s %-10s\n" "$key" "${histogram[$key]}" "(${percentage}%)" 
done

exit 0
