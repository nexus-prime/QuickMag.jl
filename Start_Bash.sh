#! /bin/bash

JuliaPath=$(which julia)
CPUthreads=$(nproc)
if [ -z "$JuliaPath" ]
then
	echo "Julia not found. Install current stable release:  https://julialang.org/downloads/"
else
	export JULIA_NUM_THREADS=$CPUthreads
	$JuliaPath "./Run_QuickMag.jl"
fi
