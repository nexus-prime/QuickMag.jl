#!/usr/bin/env julia

#Dependencies
using JuliaDB
using DelimitedFiles 

function QuickMagCPU(ProcID,NumResults)
	WhiteListTable=load(joinpath(".","HostFiles","WhiteList.jldb"));
	LocProjKey=findall(x-> x=="cpu",select(WhiteListTable,:Type))
	OutLength=size(LocProjKey,1);
	MagFrame=[[] for ind=1:OutLength]
	Threads.@threads for ind=1:OutLength
		row=WhiteListTable[LocProjKey[ind]];
		#display(row.Project)
		if (row.TeamRAC!=Inf)	
			LocFilePath=joinpath(".","HostFiles","$(row.Type)"*"_"*"$(row.Project).jldb");
			LocHostTable=load(LocFilePath);
			#Find systems with mathcing CPUs
			shortTab=sort(filter(host -> occursin(ProcID,string(host.CPUmodel)), LocHostTable), :RAC, rev=true);
			#Get magnitude values for #NumResults best systems
			if isempty(select(shortTab,:ID))
				MagFrame[ind]=[ 0.0 ]
			else
				if size(select(shortTab,:ID),1)<NumResults
					readNum=size(select(shortTab,:ID),1);
				else
					readNum=NumResults
				end
				#Get magnitude values for #NumResults best systems
				RACvect=select(shortTab[1:readNum],:RAC);
				MagVect=(115000/row.NumWL_Proj) .* (RACvect./row.TeamRAC);
				MagFrame[ind]=MagVect
			end
		else
			MagFrame[ind]=[ ]
		end
	end
	ProjectFrame=select( filter(x-> x.Type=="cpu",WhiteListTable),:FullName)
	
	printstyled(string(lpad("Project Name|",21),"\t", "Top $NumResults magnitude(s) for $ProcID\n"),bold=:true)
	for ind=1:OutLength
		if ~isempty(MagFrame[ind])
			println(string(lpad(ProjectFrame[ind],20),"|\t",join(round.(MagFrame[ind],digits=1), "\t")))
		end
	end
	
end

function CPUsurvey(NumResults)
	WhiteListTable=load(joinpath(".","HostFiles","WhiteList.jldb"));
	LocProjKey=findall(x-> x=="cpu",select(WhiteListTable,:Type))
	OutLength=size(LocProjKey,1);
	MegaTable=[];
	for ind=1:OutLength
		row=WhiteListTable[LocProjKey[ind]];
		#display(row.Project)
		if (row.TeamRAC!=Inf)	
			LocFilePath=joinpath(".","HostFiles","$(row.Type)"*"_"*"$(row.Project).jldb");
			LocHostTable=load(LocFilePath);
			LocHostTable=filter(host -> "NOTHING" != string(host.CPUmodel), LocHostTable)
			if isempty(MegaTable)
				MegaTable=select(LocHostTable,(:ID,:CPUmodel));
			else
				MegaTable=merge(MegaTable,select(LocHostTable,(:ID,:CPUmodel)));
			end
		end
	end
	SurveyTable=sort(groupby(length, MegaTable, :CPUmodel), :length, rev=true);
	FullLength=size(select(SurveyTable,:length),1);
	printstyled("#CPUs\tModel Name\n",bold=:true)
	if FullLength>NumResults
		writedlm(stdout,select(SurveyTable,(:length,:CPUmodel))[1:NumResults])
	else
		writedlm(stdout,select(SurveyTable,(:length,:CPUmodel)))
	end
	
end

function GPUsurvey(NumResults)
	WhiteListTable=load(joinpath(".","HostFiles","WhiteList.jldb"));
	LocProjKey=findall(x-> x=="gpu",select(WhiteListTable,:Type))
	OutLength=size(LocProjKey,1);
	MegaTable=[];
	for ind=1:OutLength
		row=WhiteListTable[LocProjKey[ind]];
		#display(row.Project)
		if (row.TeamRAC!=Inf)	
			LocFilePath=joinpath(".","HostFiles","$(row.Type)"*"_"*"$(row.Project).jldb");
			LocHostTable=load(LocFilePath);
			LocHostTable=filter(host -> "NONE" != host.GPUmodel, LocHostTable)
			LocHostTable=filter(host -> ~occursin("HD GRAPHICS",split(string(host.GPUmodel),']')[1]), LocHostTable)
			if isempty(MegaTable)
				MegaTable=select(LocHostTable,(:ID,:GPUmodel));
			else
				MegaTable=merge(MegaTable,select(LocHostTable,(:ID,:GPUmodel)));
			end
		end
	end
	SurveyTable=sort(groupby(length, MegaTable, :GPUmodel), :length, rev=true);
	FullLength=size(select(SurveyTable,:length),1);
	printstyled("#GPUs\tModel Name\n",bold=:true)
	if FullLength>NumResults
		writedlm(stdout,select(SurveyTable,(:length,:GPUmodel))[1:NumResults])
	else
		writedlm(stdout,select(SurveyTable,(:length,:GPUmodel)))
	end
	
end


function QuickMagGPU(CoProcID,NumResults)
	#CoProcID=uppercase(CoProcID);
	GPUtype=[];
	if	(occursin("NVIDIA",CoProcID)||occursin("GTX",CoProcID)||occursin("RTX",CoProcID)||occursin("TESLA",CoProcID)||occursin("TITAN",CoProcID)||occursin("NVS",CoProcID)||occursin("QUADRO",CoProcID)||occursin("GT",CoProcID))
		GPUtype="CUDA"
	end
	if isempty(GPUtype)&&((occursin("INTEL",CoProcID))||(occursin("HD GRAPHICS",CoProcID))||(occursin("IRIS",CoProcID)))
		GPUtype="INTEL"
	elseif(isempty(GPUtype))
		GPUtype="CAL"
	end
	
	WhiteListTable=load(joinpath(".","HostFiles","WhiteList.jldb"));
	LocProjKey=findall(x-> x=="gpu",select(WhiteListTable,:Type))
	OutLength=size(LocProjKey,1);
	MagFrame=[[] for ind=1:OutLength]	
	for ind=1:OutLength
		row=WhiteListTable[LocProjKey[ind]];
		
		if (row.TeamRAC!=Inf)	
			LocFilePath=joinpath(".","HostFiles","$(row.Type)"*"_"*"$(row.Project).jldb")
			LocHostTable=load(LocFilePath)
			#Find systems with mathcing GPUs
			shortTab=sort(filter(host -> occursin(CoProcID,string(host.GPUmodel)), LocHostTable), :RAC, rev=true);
			#Remove Multi GPU systems
			if GPUtype=="CUDA"
				shortTab=filter(host -> ~occursin("CAL",string(host.GPUmodel)), shortTab)
				shortTab=filter(host -> occursin("|1|",split(string(host.GPUmodel),']')[findfirst(x->occursin("CUDA",x),split(host.GPUmodel,']'))]), shortTab)
			elseif GPUtype=="CAL"
				shortTab=filter(host -> ~occursin("CUDA",string(host.GPUmodel)), shortTab)
				shortTab=filter(host -> occursin("|1|",split(string(host.GPUmodel),']')[findfirst(x->occursin("CAL",x),split(host.GPUmodel,']'))]), shortTab)
			else
				shortTab=filter(host -> ~occursin("CAL",string(host.GPUmodel)), shortTab)
				shortTab=filter(host -> ~occursin("CUDA",string(host.GPUmodel)), shortTab)
				shortTab=filter(host -> occursin("|1|",split(string(host.GPUmodel),']')[findfirst(x->occursin("INTEL",x),split(host.GPUmodel,']'))]), shortTab)
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
				RACvect=select(shortTab[1:readNum],:RAC);
				MagVect=(115000/row.NumWL_Proj) .* (RACvect./row.TeamRAC);
				MagFrame[ind]=MagVect
			end
		else
			MagFrame[ind]=[ ]
		end
	end	
	ProjectFrame=select(filter(x-> x.Type=="gpu",WhiteListTable),:FullName)
	
	printstyled(string(lpad("Project Name|",21),"\t", "Top $NumResults magnitude(s) for $CoProcID\n"),bold=:true)
	for ind=1:OutLength
		if ~isempty(MagFrame[ind])
			println(string(lpad(ProjectFrame[ind],20),"|\t",join(round.(MagFrame[ind],digits=1), "\t")))
		end
	end

end
