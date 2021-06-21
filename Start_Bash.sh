#! /bin/bash

if ! command -v julia &> /dev/null	#Check if Julia is installed
then
	echo "Julia not found"
	echo "Add to Julia to path or install the current stable release from:  https://julialang.org/downloads/"
else
	FreeRAM=$(free -b | grep Mem | grep -Eo [0-9]* | head -n 3 | tail -n 1)
	lowMemoryOpt=$(julia -E "($FreeRAM/ 1024^3 / 4.1)<1")
	if "$lowMemoryOpt" == "true"				#Detect amount of memory available
	then
		export JULIA_NUM_THREADS=$(julia -E round\(Int,$(nproc)/2\) )	#Use reduced threads if on low memory device
	else
		export JULIA_NUM_THREADS=$(nproc)	#Set enviroment variable to tell Julia how many threads to use
	fi	
	julia "./Run_QuickMag.jl"				#Start QuickMag CLI
fi
