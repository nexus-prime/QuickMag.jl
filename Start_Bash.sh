#! /bin/bash

CPUthreads=$(nproc)		#Detect number of available CPU threads
if ! command -v julia &> /dev/null	#Check if Julia is installed
then
	echo "Julia not found"
	echo "Add to Julia to path or install the current stable release from:  https://julialang.org/downloads/"
else
	export JULIA_NUM_THREADS=$CPUthreads	#Set enviroment variable to tell Julia how many threads to use
	julia "./Run_QuickMag.jl"				#Start QuickMag CLI
fi
