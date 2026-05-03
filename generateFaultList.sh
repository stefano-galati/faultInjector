#!/bin/bash

if [[ $# -ne 3 && $# -ne 4 ]]; then
  echo -e "Usage: $0 <targetRange> <maskRange> <faultTypes> <bitflipInstant>
  targetRange  e.g. 1-2
  maskRange    e.g. 1-7 (can also be provided in this way: every_bit,32 every_bit,16 ...)
  faultTypes   comma-separated, e.g. ST0,ST1,BITFLIP
  bitflipInstants  e.g. 1-10 (applied only to BITFLIP faults)
  Example:  $0 1-2 1-7 ST0,ST1,BITFLIP 1-10"
  exit 1
fi



targetRange="$1"
maskRange="$2"
faultCsv="$3"
bitflipInstants="$4"

expand_range() {
  local expr="$1"
  local -n _out=$2  # nameref output
  _out=()
  
	# When "every_bit" is given as first argument
	if [[ "$expr" == every_bit,* ]]; then
	IFS=',' read -r _ num_bits <<< "$expr"

	if [[ -n "$num_bits" ]]; then
		for ((i=0; i<num_bits; i++)); do
		    if (( i == 0 )); then
		        _out+=( "0" )
		    else
		        _out+=( "$((1 << (i-1)))" )
		    fi
		done
	fi
		return 0
	fi

  
  IFS=',' read -r -a tokens <<< "$expr"
  for token in "${tokens[@]}"; do
    token="${token#"${token%%[![:space:]]*}"}" # trim left
    token="${token%"${token##*[![:space:]]}"}" # trim right
    if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      local start=${BASH_REMATCH[1]}
      local end=${BASH_REMATCH[2]}
      if (( start <= end )); then
        for ((i=start; i<=end; i++)); do _out+=( "$i" ); done
      else
        for ((i=start; i>=end; i--)); do _out+=( "$i" ); done
      fi
    elif [[ "$token" =~ ^[0-9]+$ ]]; then
      _out+=( "$token" )
    else
      echo "Invalid number or range: $token" >&2
      exit 2
    fi
  done
}

# Split comma-separated faults into array (preserve order, trim whitespace)
IFS=',' read -r -a faults_raw <<< "$faultCsv"
faults=()
for f in "${faults_raw[@]}"; do
  # Trim whitespace
  f="${f#"${f%%[![:space:]]*}"}"
  f="${f%"${f##*[![:space:]]}"}"
  [[ -n "$f" ]] && faults+=( "$f" )
done

# Expand ranges
expand_range "$targetRange" targets
expand_range "$maskRange" masks
expand_range "$bitflipInstants" instants


# Print header (exactly as your sample)
printf "#Id;targetReg;Mask;FaultType\n"

# Generate entries: for each target -> for each fault (in given order) -> for each mask (ascending order)
for tgt in "${targets[@]}"; do
  for fault in "${faults[@]}"; do
    for m in "${masks[@]}"; do
      if [[ $fault == "BITFLIP" ]] && [[ "$bitflipInstants" ]]; then
      		for instant in "${instants[@]}"; do
          	printf "%s_%s_%s_%s;%s;%s;%s;%s\n" "$tgt" "$fault" "$m" "$instant" "$tgt" "$m" "$fault" "$instant"
      		done
      else
      	printf "%s_%s_%s;%s;%s;%s\n" "$tgt" "$fault" "$m" "$tgt" "$m" "$fault"
      fi
    done
  done
done
