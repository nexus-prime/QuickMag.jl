@echo off

title QuickMag.jl

julia -t auto --version
if errorlevel 1 echo. && echo Julia not found. && echo Add to Julia to path or install the current stable release from:  https://julialang.org/downloads/ && echo.  && pause && exit

julia -t auto Run_QuickMag.jl

pause