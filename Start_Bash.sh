#! /bin/bash


CPUthreads=$(nproc)
FreeRAM=$(free -b | grep Mem | grep -Eo [0-9]* | head -n 3 | tail -n 1)
lowMemoryOpt=$(julia -E "($FreeRAM/ 1024^3 / 5.75)<1")

if "$lowMemoryOpt" == "true"
then
	export JULIA_NUM_THREADS=2
	julia "./Run_QuickMag.jl"
else
	export JULIA_NUM_THREADS=$CPUthreads
	julia "./Run_QuickMag.jl"
fi
