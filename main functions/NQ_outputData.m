function [data] = NQ_outputData (paramsIn, expFolder)
% NQ_outputData will create analysis data file.
%
% Part of NET-QUANT.
%
%
%
% Pontus Nordenfelt 02/2017


%% ------ Parameters ------- %%
pString = 'data_'; %The string to prepend before the background mask directory & channel name
dName = 'data'; %String for naming the directory
p = paramsIn;


%% ------- Initialization------%%
[~, analysis] = NQ_loadStruct(expFolder,'analysis');
[~, threshold] = NQ_loadStruct([p.targetDir filesep p.controlPath],'threshold');

%Create string for current directory
currDir = [expFolder filesep dName];

%Check/create directory
mkClrDir(currDir);


%% Output data
%check for analysis structure variable
if ~isstruct(analysis)
    cellCount=0;
    positiveCells=0;
    percentageNet=0;
    
else
    %display numbers
    cellStats=analysis.cellStats;
    cellCount=numel(cellStats.CellNr(:));
    
    
    
    %determine net-positive cells
    positiveCells(cellCount) = false;
    
    %create variable to record type of net ID
    netID(cellCount) = 0;
    
    for iCell = 1:cellCount
        netcell=false;
        netID(iCell) = 0;
        if cellStats.Area(iCell)>threshold.medianNetSize %net area larger than average control cell
            if cellStats.Area(iCell)>...
                    threshold.medianNetSize*p.areaInc %net area increase over average cell
                netcell=true;
                netID(iCell)=1;
            end
            if cellStats.CircularityDNA(iCell)<p.deformationInc
                
                
                netcell=true;
                netID(iCell)=2;
            end
            
            if cellStats.ratioArea(iCell)>p.ratioInc
                
                netcell=true;
                netID(iCell)=3;
            end
            
        end
        positiveCells(iCell) = netcell;
    end
    
    %add NET-positive cells
    T=analysis.table.all;
    T2=addvars(T,transpose(positiveCells),'After','cellNr', 'NewVariableNames','NETpositive');
    
    %add image name
    [~, fileName, ] = fileparts(expFolder);
    data.imageName = fileName;
    
    data.area = cellStats.Area;
    data.cellNr = cellStats.CellNr;
    data.table=T2;
    data.netID = netID;
    
    %select output data
    percentageNet = sum(positiveCells)/cellCount*100;
    
    disp(['cell count:' num2str(cellCount)]);
    
    disp(['net positive cells:' num2str(percentageNet) '%']);
    
end


data.cellCount =cellCount;
data.positiveCells = positiveCells;
data.percentageNet = percentageNet;


save ([expFolder filesep dName filesep 'data.mat'],'data');


end