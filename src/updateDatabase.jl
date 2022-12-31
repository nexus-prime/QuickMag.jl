#!/usr/bin/env julia

#Dependencies
#using JuliaDB
using HTTP
using CodecZlib
using EzXML
using Gumbo
using Cascadia
using Dates
using DataFrames
using CSV
using Terming
using PrettyTables

#Functions
function PareDownIO(MyIOSTREAM) #Reduce Size of XML Files (keep RAM usage as small as possible)
	ParedIO=IOBuffer(append=true);

		for LocLine in eachline(MyIOSTREAM)
			if occursin("credit",LocLine) || occursin("id",LocLine) || occursin("model",LocLine) || occursin("host",LocLine) || occursin("coproc",LocLine) || occursin("xml",LocLine)
				println(ParedIO, string(LocLine));
			end
		end

	return ParedIO
	close(ParedIO)
end

function MyStreamXMLparse(XMLstream,OutFile) #Read XML files line by line and extract desired values (avoids memory leak from libXML2)
reader = EzXML.StreamReader(XMLstream)
	#println("Loaded Reader")
	#Arrays to accumulate needed data
	LocHostID = [];
	LocTotCred = [];
	LocRAC = [];
	LocPModel = [];
	LocGModel = [];
	
	#Flags to indicate if all values where found for each host
	foundID=true
	foundTotCred=true
	foundRAC=true
	foundPModel=true
	foundGModel=true
	
	for line in reader
		if (reader.type==1) && (reader.name=="host") # If we find new host reset flags for new node
			if foundID==false
				push!(LocHostID,"0")
			end
			if foundTotCred==false
				push!(LocTotCred,"0")
			end
			if foundRAC==false
				push!(LocRAC,"0")
			end			
			if foundPModel==false
				push!(LocPModel,"NONE")
			end		
			if foundGModel==false
				push!(LocGModel,"NONE")
			end		
			foundID=false
			foundTotCred=false
			foundRAC=false
			foundPModel=false
			foundGModel=false			
		end
		#Locate which data type we found and save value
		if (reader.type==1) && (reader.name=="id") # Type=1 is an element/node
			push!(LocHostID,reader.content)
			foundID=true
		end
		if (reader.type==1) && (reader.name=="total_credit") # Type=1 is an element/node
			push!(LocTotCred,reader.content)
			foundTotCred=true
		end
		if (reader.type==1) && (reader.name=="expavg_credit") # Type=1 is an element/node
			push!(LocRAC,reader.content)
			foundRAC=true
		end
		if (reader.type==1) && (reader.name=="p_model") # Type=1 is an element/node
			#println(string(reader.content))
			push!(LocPModel,uppercase(string(reader.content)))
			foundPModel=true
		end
		if (reader.type==1) && (reader.name=="coprocs") # Type=1 is an element/node
			push!(LocGModel,uppercase(string(reader.content)))
			foundGModel=true
		end
	end
	#Final cleanup in case last host had missing data
	if foundID==false
		push!(LocHostID,"0")
	end
	if foundTotCred==false
		push!(LocTotCred,"0")
	end
	if foundRAC==false
		push!(LocRAC,"0")
	end			
	if foundPModel==false
		push!(LocPModel,"NOTHING")
	end		
	if foundGModel==false
		push!(LocGModel,"NONE")
	end		
	
	LocHostID=parse.([Int64],LocHostID)
	LocTotCred=parse.([Float64],LocTotCred)
	LocRAC=parse.([Float64],LocRAC)
	LocPModel=string.(LocPModel)
	LocGModel=string.(LocGModel)
	
	#LocalTable=table(LocHostID,LocPModel,LocGModel,LocTotCred,LocRAC; names = [:ID, :CPUmodel, :GPUmodel, :TotCred, :RAC]);
	LocalTable=DataFrame(ID=LocHostID,CPUmodel=LocPModel,GPUmodel=LocGModel,TotCred=LocTotCred,RAC=LocRAC)
	
	LocalTable=filter(host -> host.RAC > 1.0 , LocalTable)		#Remove any inactive hosts from database
	CSV.write(OutFile,LocalTable)
	

end


function redispStatusDF(statusDF,WLlength,printLock)
	numLines=4+WLlength	
	lock(printLock)
	try
		Terming.cmove_up(numLines)
		pretty_table(statusDF;alignment=:l, nosubheader=true)	
	finally
		unlock(printLock)
	end
end

###
### Start Main run
###

WhiteListFile=joinpath(".","WhiteList.csv");# Import Gridcoin WhiteList from CSV file
println("Reading $WhiteListFile")
WhiteListTable=DataFrame(CSV.File(WhiteListFile));
WLlength=size(WhiteListTable,1);

#Remove old host data
FullHostFilePath=joinpath(pwd(),"HostFiles");
if isdir(FullHostFilePath)
	if Sys.iswindows()
		run(`cmd /C rmdir /Q /S $FullHostFilePath`)	#Windows File Permisions issue (workaround)
	else
		rm("HostFiles"; force=true, recursive=true);
	end
end
mkdir("HostFiles")					#Make new folder to store host data

#Check with block explorer to verify greylist/TeamRAC
statsURL="https://www.gridcoinstats.eu/project";
statsHTML=joinpath(tempdir(),"stats.html")

if Sys.iswindows()
	run(`cmd /C curl $statsURL -s -o $statsHTML`)
else
	run(`wget $statsURL -q -O $statsHTML`);
end

HTMLdat=Gumbo.parsehtml(read(statsHTML,String));
HTMLtab=eachmatch(Selector("tr"), HTMLdat.root);
TableLines=size(HTMLtab,1);
CurrentWLsize=TableLines-1;
WLTab_RACvect=[ Inf for ind=1:WLlength];
for lineNum = 2:TableLines 
	line=HTMLtab[lineNum];
	ProjName=string(line[1][1][1]);
	TeamRAC=parse(Int64,replace(string(line[7][1][1]),' ' => ""));
	locIndex=findall(x-> x==ProjName, WhiteListTable."FullName");
	
	if ~isempty(locIndex)
		WLTab_RACvect[locIndex[1]]=TeamRAC;
	else
		#Print notice if QuickMag whitelist disagrees with block explorer
		#Einstein does not publish host data, so it is not listed in WhiteList.csv
		println("    Not building host database for: $ProjName")	
	end
	
end

rm(statsHTML);


##########################
WhiteListTable."TeamRAC"=WLTab_RACvect;
WhiteListTable."NumWL_Proj"=[CurrentWLsize for ind=1:WLlength];
WhiteListTable."TimeStamp"=[Dates.now() for ind=1:WLlength];
GreyList=findall(x-> x==Inf, WhiteListTable."TeamRAC")	#Print notice if projects are on greylist
for line in GreyList
	println("    Project on greylist: $(WhiteListTable.FullName[line])")
end
println("")


println("Downloading Host Data")

global statusDF=DataFrame(Project=WhiteListTable."Project",Status=repeat(rpad.(["waiting..."],11," "),outer=WLlength))
pretty_table(statusDF;alignment=:l, nosubheader=true)
FailedDownloads=[];		#Vector to keep track of any failed downloads
printLock=ReentrantLock()

Threads.@threads for ind in 1:WLlength	#Process projects in WhiteList.csv (Runs in parallel if julia started with multiple threads)
		row=WhiteListTable[ind,:];
		sleep(rand())
		statusDF[ind,2]="downloading"
		redispStatusDF(statusDF,WLlength,printLock)			
		
			if (row."TeamRAC"!=Inf)	#Skip if project if there was no current team data available
				
				LocFilePath=joinpath(".","HostFiles","$(row.Type)"*"_"*"$(row.Project).csv") #Path to saved data
				
				try
					#Alternate between downloading & processing host data
					CompressedFileStream = Base.BufferStream();
					@async while !eof(CompressedFileStream)
						MyStreamXMLparse(PareDownIO(GzipDecompressorStream(CompressedFileStream)),LocFilePath) #Remove most unnecessary elements from XML to save RAM & Convert XML to binary JuliaDB file	
					end
					
					#Download host data and send to CompressedFileStream
					Request = HTTP.get(row.URL, response_stream=CompressedFileStream,verbose=0, connect_timeout=30, retries=3)
					
					#Wait until there is no data left in CompressedFileStream
					close(CompressedFileStream)
					statusDF[ind,2]="finished"
					redispStatusDF(statusDF,WLlength,printLock)

				catch e					#catch errors that occur if a project website is down
					statusDF[ind,2]="failed"
					redispStatusDF(statusDF,WLlength,printLock)
					push!(FailedDownloads,ind)
				end
				
			else
				statusDF[ind,2]="unavailable"
				redispStatusDF(statusDF,WLlength,printLock)
				
			end
		redispStatusDF(statusDF,WLlength,printLock)

end 



# Finalize WhiteListData.csv noting missing data (Host data & Team data from block explorer)
TeamRacVect=WhiteListTable."TeamRAC";
for jnd in FailedDownloads
	TeamRacVect[jnd] = Inf ;	
end
WhiteListTable."TeamRAC"=TeamRacVect;

CSV.write(joinpath(".","HostFiles","WhiteListData.csv"),WhiteListTable) #Save checked and parsed WhiteListTable 
