function [] = NQ_determineThreshold (paramsIn, folderPath)
% NQ_determineThreshold will analyze cell properties of control cells to
% determine threshold values.
%
% Part of NET-QUANT.
%
%
%
% Pontus Nordenfelt 02/2017


%% ------ Parameters ------- %%
pString = 'threshold_'; %The string to prepend before the background mask directory & channel name
dName = 'threshold'; %String for naming the directory
p = paramsIn;


%% Calculate threshold based on all control data

sampleFolders = getAllFolderPaths(folderPath);
sampleNames = getAllFolders(folderPath);

%check for earlier analysis and remove folder from new analysis
index = find(strcmp('threshold', sampleNames), 1);
if index>0
    sampleFolders(index)=[];
end


for iSample = 1:numel(sampleFolders)
    
    %check for analysis
    if exist([sampleFolders{iSample} filesep 'analysis' filesep 'analysis.mat'],'file')
        [~, analysis] = NQ_loadStruct(sampleFolders{iSample},'analysis');
        
        T=analysis.table.all;
    else
        error (['no analysis found for ' sampleFolders{iSample}]);
    end
end

%calculate threshold values for size and shape
%area and eccentricicty

threshold.medianNucleiSize = median(T.dnaArea);
threshold.medianNetSize = median(T.netArea);
threshold.medianRatioArea = median(T.ratioArea);
threshold.medianNucleiCircularity = median(T.dnaCircularity);

%mean calculations
threshold.meanNucleiSize = mean(T.dnaArea);
threshold.meanNetSize = mean(T.netArea);
threshold.meanRatioArea = mean(T.ratioArea);
threshold.meanNucleiCircularity = mean(T.dnaCircularity);

%std calculations
threshold.stdNucleiSize = std(T.dnaArea);
threshold.stdNetSize = std(T.netArea);
threshold.stdRatioArea = std(T.ratioArea);
threshold.stdNucleiCircularity = std(T.dnaCircularity);


%Create string for current directory
currDir = [folderPath filesep dName];

%Check/create directory
mkClrDir(currDir);

%save data
save ([folderPath filesep dName filesep 'threshold.mat'],'threshold');


end