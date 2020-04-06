function [] = NQ_getCellProperties (paramsIn, expFolder)
% NQ_getCellProperties will analyze cell properties.
%
% Part of NET-QUANT.
%
%
%
% Pontus Nordenfelt 02/2017


%% ------ Parameters ------- %%
pString = 'analysis_'; %The string to prepend before the background mask directory & channel name
dName = 'analysis'; %String for naming the directory
p = paramsIn;


%% ------- Initialization------%%
[~, masks] = NQ_loadStruct(expFolder,'masks');
[~, labels] = NQ_loadStruct(expFolder,'labels');
[~, ims] = NQ_loadStruct(expFolder,'ims');

load([expFolder filesep 'NQ_metadata.mat']); %load metadata

%Create string for current directory
currDir = [expFolder filesep dName];

%Check/create directory
mkClrDir(currDir);


p.combineConnected = 1; %combine cells where DNA is covered by NET signal.




%% Calculate nets

statsList = {
    'Area',...
    'Perimeter',...
    'Eccentricity',...
    'MajorAxisLength',...
    'MinorAxisLength',...
    'MaxIntensity',...
    'MeanIntensity',...
    'MinIntensity',...
    'WeightedCentroid',...
    'Centroid',...
    'BoundingBox'};

%find overlap in labels, only count cell if there is only exactly 1
%solution

%assign data
bw1 = masks.channels.(p.nucleiName);
bw2 = masks.channels.(p.netName);
L1 = labels.channels.(p.nucleiName);
L2 = labels.channels.(p.netName);
I1 = ims.channels.(p.nucleiName);
I2 = ims.channels.(p.netName);

%compute the set of pixels that belong to the foreground in both images
overlap = bw1 & bw2;

% Check for cells else abort
if sum(overlap(:))==0 
    disp ('no cells found, aborting analysis for image!');
    analysis = 0;
    metadata.flags.NQ_analysis = 0;
else
    
    
    
    %check class of label matrix and convert if necessary
    if isa(L1,'uint16') && isa(L2,'uint8')
        L2 = cast(L2,'uint16');
    end
    if isa(L1,'uint8') && isa(L2,'uint16')
        L1 = cast(L1,'uint16');
    end
    
    %compute the corresponding label pairs by using logical indexing into the two label matrices
    pairs = [L1(overlap), L2(overlap)];
    
    %eliminate the duplicates in the list of pairs
    pairs = unique(pairs, 'rows');
    
    %create new label matrices with only overlapping cells
    ind1 = pairs(:,1); %index
    L1(~ismember(L1,ind1))=0;
    ind2 = pairs(:,2); %index
    L2(~ismember(L2,ind2))=0;
    
    %optional exclusion of areas covering multiple cells
    if p.combineConnected == 1 && length(pairs(:,1))>1
        p1 = pairs(:,1);
        u2 = double(unique(p1));
        count = hist(p1,u2); %nr of repeated elements
        dup1=find(count>1); %get repeated elements
        for iInd = 1:numel(dup1)
            x = u2(dup1(iInd)); %repeated label
            pos = find(p1==x); %pos of repeated label
            
            for iCount = 1:numel(pos)-1
                label1 =pairs(pos(iCount),2);
                if iCount>1
                    label1=newlabel; %fix for multiple adjoining sections
                end
                label2 =pairs(pos(iCount+1),2);
                newlabel=label1;
                L2(L2==label2)=newlabel; %relabel to combine area
            end
        end
        
    end
    
    %smooth and fill gaps
    se = strel('disk',1);
    u2 = double(unique(L2));
    u2(1)=[];        %remove zero
    for iLabel=1:numel(u2)
        label= u2(iLabel);           %set cell
        bw=logical(L2==label);     %make new mask of net areas
        bw2=imclose(bw,se);         %perform close operation to close gaps and smooth
        L2(L2==label)=0;           %remove old area
        L2(bw2==1)=iLabel;          %add new area, relabeling from 1
    end
    
    %update pairs
    pairs2 = [L1(overlap), L2(overlap)];
    pairs2 = unique(pairs2, 'rows');
    
    
    %get region stats for both channels
    s = regionprops(L1,I1, statsList);
    s2 = regionprops(L2,I2, statsList);
    
    % analyze cell properties
    
    
    %loop through all pairs and set stats
    for iCell = 1:length(pairs2(:,1))
        for iStats = 1:length(statsList)-3 %skip centroids and boundingbox
            stats.(statsList{iStats})(iCell,1) = s(pairs2(iCell,1)).(statsList{iStats});
            stats.(statsList{iStats})(iCell,2) = s2(pairs2(iCell,2)).(statsList{iStats});
            stats.Centroid{iCell,1} = s(pairs2(iCell,1)).Centroid;
            stats.BoundingBox{iCell,1} = s(pairs2(iCell,1)).BoundingBox;
            stats.Centroid{iCell,2} = s2(pairs2(iCell,2)).Centroid;
            stats.BoundingBox{iCell,2} = s2(pairs2(iCell,2)).BoundingBox;
        end
        stats.CellNr = pairs2;
    end
    
    
    %create stats for identified cells
    [a,idx1,idx2]=unique(stats.CellNr(:,2));
    cellStats.Area = stats.Area(idx1,2);
    cellStats.Perimeter = stats.Perimeter(idx1,2);
    cellStats.Centroid = stats.Centroid(idx1,2);
    cellStats.BoundingBox = stats.BoundingBox(idx1,2);
    cellStats.Eccentricity = stats.Eccentricity(idx1,2);
    cellStats.MajorAxisLength = stats.MajorAxisLength(idx1,2);
    cellStats.MinorAxisLength = stats.MinorAxisLength(idx1,2);
    cellStats.CellNr = stats.CellNr(idx1,2);
    cellStats.MeanIntensity = stats.MeanIntensity(idx1,2);
    
    
    %sum area for DNA
    areaDNA = [double(a), accumarray(idx2,stats.Area(:,1))];
    cellStats.AreaDNA = areaDNA(:,2);
    
    %add circularity for DNA, not using summed area
    cellStats.CircularityDNA = (4 * pi * stats.Area(idx1,1))./(stats.Perimeter(idx1,1) .^ 2);
    
    %get eccentricity for DNA (potentially analyze all pixels)
    e=stats.Eccentricity(:,1);
    for iCell=1:length(idx1)
        e2 = e(idx2==iCell); %find eccentricty for all dna in cell
        cellStats.EccentricityDNA(iCell,1) = max(e2); %take the highest value
    end
    
    %get intensity for DNA (potentially analyze all pixels)
    i=stats.MeanIntensity(:,1);
    for iCell=1:length(idx1)
        i2 = i(idx2==iCell); %find mean intensity for all dna in cell
        cellStats.MeanIntensityDNA(iCell,1) = mean(i2); %average the values
    end
    
    %get image name and fill a vector with the length of number of cells
    [~, fileName, ] = fileparts(expFolder);
    %imageName = repmat(fileName,[1 length(pairs2)]);
    imageName = cell(length(idx1),1);
    imageName(:) = {fileName};
    
    
    %create table of stats
    cellNr = cellStats.CellNr;
    dnaArea = cellStats.AreaDNA;
    netArea = cellStats.Area;
    ratioArea = dnaArea./netArea;
    cellStats.ratioArea = ratioArea; %store in cellStats as well
    dnaCircularity = cellStats.CircularityDNA;
    dnaEccentricity = cellStats.EccentricityDNA;
    netEccentricity = cellStats.Eccentricity;
    dnaMeanInt = cellStats.MeanIntensityDNA;
    netMeanInt = cellStats.MeanIntensity;
    
    
    Tall = table(imageName, cellNr,dnaArea, netArea, ratioArea, dnaCircularity, ...
        dnaEccentricity, netEccentricity, dnaMeanInt, netMeanInt);
    
    
    %store images and stats table
    analysis.table.all = Tall;
    
    analysis.label.(p.nucleiName) = L1;
    analysis.label.(p.netName) = L2;
    analysis.stats = stats;
    analysis.cellStats = cellStats;
    
    %set metadata flag
    metadata.flags.NQ_analysis = 1;
end


save ([expFolder filesep dName filesep 'analysis.mat'],'analysis');

%save metadata


save([expFolder filesep 'NQ_metadata.mat'],'metadata');


end