#!/usr/bin/env julia

#Dependencies
using DataFrames
using CSV
using DelimitedFiles 

function QuickMagCPU(ProcID,NumResults)
	WhiteListTable=DataFrame(CSV.File(joinpath(".","HostFiles","WhiteListData.csv")));
	LocProjKey=findall(x-> x=="cpu",WhiteListTable.Type);
	OutLength=size(LocProjKey,1);
	MagFrame=[[] for ind=1:OutLength]
	Threads.@threads for ind=1:OutLength
		row=WhiteListTable[LocProjKey[ind],:];
		#display(row.Project)
		if (row.TeamRAC!=Inf)	
			LocFilePath=joinpath(".","HostFiles","$(row.Type)"*"_"*"$(row.Project).csv");
			LocHostTable=DataFrame(CSV.File(LocFilePath))
			#Find systems with mathcing CPUs
			shortTab=sort(filter(host -> occursin(ProcID,string(host.CPUmodel)), LocHostTable), :RAC, rev=true);
			#Get magnitude values for #NumResults best systems
			if isempty(shortTab.ID)
				MagFrame[ind]=[ 0.0 ]
			else
				if size(shortTab.ID,1)<NumResults
					readNum=size(shortTab.ID,1);
				else
					readNum=NumResults
				end
				#Get magnitude values for #NumResults best systems
				RACvect=shortTab[1:readNum,:].RAC;
				MagVect=(115000/row.NumWL_Proj) .* (RACvect./row.TeamRAC);
				MagFrame[ind]=MagVect
			end
		else
			MagFrame[ind]=[ ]
		end
	end
	ProjectFrame=select( filter(x-> x.Type=="cpu",WhiteListTable),:FullName)
	
	printstyled(string(lpad("Project Name|",21),"   ", "Top $NumResults magnitude(s) for $ProcID      \n"),bold=:true,underline=true)
	for ind=1:OutLength
		locMags=string.(round.(MagFrame[ind],digits=1))
		locEntries=size(locMags,1)
		extras=["NULL" for i=1:NumResults-locEntries]
		locMags=lpad.(vcat(locMags,extras),5);
			println(string(lpad(ProjectFrame[ind,1],20),"|\t",join(locMags, "\t")))
	end
	
end

function CPUsurvey(NumResults)
	WhiteListTable=DataFrame(CSV.File(joinpath(".","HostFiles","WhiteListData.csv")));
	LocProjKey=findall(x-> x=="cpu",WhiteListTable.Type);
	OutLength=size(LocProjKey,1);
	MegaTable=[];
	for ind=1:OutLength
		row=WhiteListTable[LocProjKey[ind],:];

		if (row.TeamRAC!=Inf)	
			LocFilePath=joinpath(".","HostFiles","$(row.Type)"*"_"*"$(row.Project).csv");
			LocHostTable=DataFrame(CSV.File(LocFilePath))
			LocHostTable=filter(host -> "NOTHING" != (host.CPUmodel), LocHostTable)
			if isempty(MegaTable)
				MegaTable=select(LocHostTable,[:ID,:CPUmodel]);
			else
				MegaTable=vcat(MegaTable,select(LocHostTable,[:ID,:CPUmodel]));
			end
		end
	end
	#SurveyTable=sort(groupby(length, MegaTable, :CPUmodel), :length, rev=true);
	SurveyTable=sort(combine(groupby(MegaTable,:CPUmodel), nrow => :count),:count,rev=:true)
	FullLength=size(SurveyTable,1);
	printstyled("#CPUs\t\tModel Name\n",bold=:true,underline=:true)
	if FullLength>NumResults
		writedlm(stdout,hcat(SurveyTable.count, SurveyTable.CPUmodel)[1:NumResults,:],"\t\t")
	else
		writedlm(stdout,hcat(SurveyTable.count, SurveyTable.CPUmodel),"\t\t")
	end
	
end

function GPUsurvey(NumResults)
	WhiteListTable=DataFrame(CSV.File(joinpath(".","HostFiles","WhiteListData.csv")));
	LocProjKey=findall(x-> x=="gpu",WhiteListTable.Type);
	OutLength=size(LocProjKey,1);
	MegaTable=[];
	for ind=1:OutLength
		row=WhiteListTable[LocProjKey[ind],:];
		#display(row.Project)
		if (row.TeamRAC!=Inf)	
			LocFilePath=joinpath(".","HostFiles","$(row.Type)"*"_"*"$(row.Project).csv");
			LocHostTable=DataFrame(CSV.File(LocFilePath))
			LocHostTable=filter(host -> "NONE" != host.GPUmodel, LocHostTable)
			LocHostTable=filter(host -> ~occursin("HD GRAPHICS",split(string(host.GPUmodel),']')[1]), LocHostTable)
			if isempty(MegaTable)
				MegaTable=select(LocHostTable,[:ID,:GPUmodel]);
			else
				MegaTable=vcat(MegaTable,select(LocHostTable,[:ID,:GPUmodel]));
			end
		end
	end
	MegaTable.GPUmodel=replace.(MegaTable.GPUmodel, "[CUDA|" => "","[CAL|" => "","[INTEL|" => "","[OPENCL_GPU|" => "",r"MB.*" => "MB", r"^\[BOINC\|[0-9]\.[0-9]+\.[0-9]+\]" =>"")#
	SurveyTable=sort(combine(groupby(MegaTable,:GPUmodel), nrow => :count),:count,rev=:true)
	FullLength=size(SurveyTable,1);
	printstyled("#GPUs\t\tModel Name\n",bold=:true,underline=:true)
	if FullLength>NumResults
		writedlm(stdout,hcat(SurveyTable.count, SurveyTable.GPUmodel)[1:NumResults,:],"\t\t")
	else
		writedlm(stdout,hcat(SurveyTable.count, SurveyTable.GPUmodel),"\t\t")
	end
	
end


function QuickMagGPU(CoProcID,NumResults)
	#CoProcID=uppercase(CoProcID);
	GPUtype=[];
	if	(occursin("NVIDIA",CoProcID)||occursin("GTX",CoProcID)||occursin("RTX",CoProcID)||occursin("TESLA",CoProcID)||occursin("TITAN",CoProcID)||occursin("NVS",CoProcID)||occursin("QUADRO",CoProcID)||occursin("GT",CoProcID))
		GPUtype="CUDA"
	end
	if isempty(GPUtype)&&((occursin("Apple",CoProcID)||(occursin("M1",CoProcID))))
		GPUtype="Apple"
	elseif isempty(GPUtype)&&((occursin("INTEL",CoProcID))||(occursin("HD GRAPHICS",CoProcID))||(occursin("IRIS",CoProcID)))
		GPUtype="INTEL"
	elseif(isempty(GPUtype))
		GPUtype="CAL"
	end
	
	WhiteListTable=DataFrame(CSV.File(joinpath(".","HostFiles","WhiteListData.csv")));
	LocProjKey=findall(x-> x=="gpu",WhiteListTable.Type);
	OutLength=size(LocProjKey,1);
	MagFrame=[[] for ind=1:OutLength]	
	for ind=1:OutLength
		row=WhiteListTable[LocProjKey[ind],:];
		
		if (row.TeamRAC!=Inf)	
			LocFilePath=joinpath(".","HostFiles","$(row.Type)"*"_"*"$(row.Project).csv")
			LocHostTable=DataFrame(CSV.File(LocFilePath))
			#Find systems with mathcing GPUs
			shortTab=sort(filter(host -> occursin(CoProcID,string(host.GPUmodel)), LocHostTable), :RAC, rev=true);
			#Remove Multi GPU systems
			if GPUtype=="CUDA"
				shortTab=filter(host -> ~occursin("CAL",string(host.GPUmodel)), shortTab)
				shortTab=filter(host -> occursin("|1|",split(string(host.GPUmodel),']')[findfirst(x->occursin("CUDA",x),split(host.GPUmodel,']'))]), shortTab)
			elseif GPUtype=="CAL"
				shortTab=filter(host -> ~occursin("CUDA",string(host.GPUmodel)), shortTab)
				shortTab=filter(host -> occursin("|1|",split(string(host.GPUmodel),']')[findfirst(x->occursin("CAL",x),split(host.GPUmodel,']'))]), shortTab)
			elseif GPUtype=="INTEL"
				shortTab=filter(host -> ~occursin("CAL",string(host.GPUmodel)), shortTab)
				shortTab=filter(host -> ~occursin("CUDA",string(host.GPUmodel)), shortTab)
				shortTab=filter(host -> occursin("|1|",split(string(host.GPUmodel),']')[findfirst(x->occursin("INTEL",x),split(host.GPUmodel,']'))]), shortTab)
			else
				shortTab=filter(host -> ~occursin("CAL",string(host.GPUmodel)), shortTab)
				shortTab=filter(host -> ~occursin("CUDA",string(host.GPUmodel)), shortTab)
				shortTab=filter(host -> occursin("|1|",split(string(host.GPUmodel),']')[findfirst(x->occursin("OPENCL_GPU",x),split(host.GPUmodel,']'))]), shortTab)				
			end
			
			if isempty(select(shortTab,:ID))
				MagFrame[ind]=[ 0.0 ]
			else
				if size(select(shortTab,:ID),1)<NumResults
					readNum=size(select(shortTab,:ID),1);
				else
					readNum=NumResults
				end
				#Get magnitude values for #NumResults best systems
				RACvect=shortTab[1:readNum,:].RAC;
				MagVect=(115000/row.NumWL_Proj) .* (RACvect./row.TeamRAC);
				MagFrame[ind]=MagVect
			end
		else
			MagFrame[ind]=[ ]
		end
	end	
	ProjectFrame=select(filter(x-> x.Type=="gpu",WhiteListTable),:FullName)
		
	printstyled(string(lpad("Project Name|",21),"   ", "Top $NumResults magnitude(s) for $CoProcID      \n"),bold=:true,underline=true)
	for ind=1:OutLength
		locMags=string.(round.(MagFrame[ind],digits=1))
		locEntries=size(locMags,1)
		extras=["NULL" for i=1:NumResults-locEntries]
		locMags=lpad.(vcat(locMags,extras),5);
			println(string(lpad(ProjectFrame[ind,1],20),"|\t",join(locMags, " \t")))
	end

end
