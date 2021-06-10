#!/usr/bin/env julia

printstyled("Starting QuickMag\n",bold=:true)
println()

printstyled("Updating dependencies...\n",bold=:true)
include(joinpath(".","src","updateDependencies.jl"))
println()

using JuliaDB
using Dates
using REPL.TerminalMenus


printstyled("Checking database status...\n",bold=:true)
ExistingDatabase=isfile(joinpath(".","HostFiles","WhiteList.jldb"));
if ExistingDatabase
	CurrentTime=Dates.now()
	WhiteListTable=WhiteListTable=load(joinpath(".","HostFiles","WhiteList.jldb"));
	UpdateTime=WhiteListTable[1].TimeStamp		
	DayFrac=round(Millisecond(CurrentTime-UpdateTime)/Millisecond(Day(1)),digits=2); #Get number of days since last update
	if DayFrac<1.0
		printstyled("Database has recently been updated\n")			#Skip option to update if less than 24 hours
		println()
	else
		printstyled("Database last updated $DayFrac days ago\n")		#Offer update if >24 hours and databases exist
		options = ["Yes", "No"]
		menu = RadioMenu(options, pagesize=2)
		choice = request("Would you like to get fresh data?", menu)
		println()
		if choice==1
			printstyled("Rebuilding database of BOINC hosts:\n",bold=:true)
			include(joinpath(".","src","updateDatabase.jl"))
			println()
		else
			printstyled("Continuing with current database of BOINC hosts\n")
			println()
		end
		
	end
	
else											#Force update if there is no database files
	printstyled("No database found. Building new database of BOINC hosts:\n",bold=:true)
	include(joinpath(".","src","updateDatabase.jl"))
	println()
end
include(joinpath(".","src","QM_EvalFuntions.jl"))

printstyled("QuickMag is ready:\n",bold=:true)

while(true)

	RunOptions = ["Estimate CPU Performance", "Estimate GPU Performance", "BOINC CPU Survey", "BOINC GPU Survey", "Exit"]
	RunMenu = RadioMenu(RunOptions, pagesize=5)
	RunChoice = request("\nWhat would you like to do?", RunMenu)
	
	if RunChoice == 1		#Run QuickMagCPU(CPUid,Number)
		println()
		try
		println("Enter CPUid string to search for: (e.g. 'i7-6700 CPU', 'ryzen 9 3900X', ...)")
		LocCPUid=uppercase(readline());
		println("Max number of results per project? (Default 5)")
		LocNumber=readline();
		if isempty(LocNumber)
			LocNumber="5"
		end
		LocNumber = parse(Int32, LocNumber)
		
		
		println("Calculating...")
		println()
		QuickMagCPU(LocCPUid,LocNumber)
		println()
		
		catch LocError
			println("Failed: $LocError")
			println()
		end
	end
	if RunChoice == 2		#Run QuickMagGPU(GPUid,Number)
		println()
		try
		println("Enter GPUid string to search for: (e.g. 'RTX 3060', 'RX 5700 XT', ...)")
		LocGPUid=uppercase(readline());
		println("Max number of results per project? (Default 5)")
		LocNumber=readline();
		if isempty(LocNumber)
			LocNumber="5"
		end
		LocNumber = parse(Int32, LocNumber)

		
		println("Calculating...")
		println()
		QuickMagGPU(LocGPUid,LocNumber)
		println()
		
		catch LocError
			println("Failed: $LocError")
			println()
		end		
	end	

	if RunChoice == 3		#Run CPU survey
		println()
		try
		println("Max number of CPU models to return? (Default 100)")
		LocNumber=readline();
		if isempty(LocNumber)
			LocNumber="100"
		end
		LocNumber = parse(Int32, LocNumber)

		println("Calculating...")
		println()
		CPUsurvey(LocNumber)
		println()
		
		catch LocError
			println("Failed: $LocError")
			println()
		end		
	end
	if RunChoice == 4		#Run GPU survey
		println()
		try
		println("Max number of GPU models to return? (Default 100)")
		LocNumber=readline();
		if isempty(LocNumber)
			LocNumber="100"
		end
		LocNumber = parse(Int32, LocNumber)

		
		println("Calculating...")
		println()
		GPUsurvey(LocNumber)
		println()
		
		catch LocError
			println("Failed: $LocError")
			println()
		end		
	end	
	if RunChoice == 5		#Exit Program
		break
	end
end

exit()
