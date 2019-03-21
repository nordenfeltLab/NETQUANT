%   *NET-QUANT: NEUTROPHIL EXTRACELLULAR TRAPS QUANTIFICATION SOFTWARE*
% -----------------------------------------------------------------------
% Software for automatic identification and quantification of neutrophil
% extracellular traps.
%
% Part I: Setup and preparation of images and sample lists.
%
% Dependencies:
%
%                 matlab/image processing toolbox
%                 NQ_prepareData
%                 getAllFileNames
%                 getAllFolderPaths
%
%
% Pontus Nordenfelt, Lund University, 02/2017
% version 0.2
%--------------------------------------------------------------------------
%% 1.1 Settings
%   Specificy naming convention, definitiions, segmentation method etc

%source folder
p.folder = '/Users/pontus/Documents/Research/Data/Current data/NET-QUANT/NET-Q test 3';

%target folder
p.targetDir ='/Users/pontus/Documents/Research/Data/Current data/NET-QUANT/test results 3';

%control images
p.controlPath = 'control';

%image type
p.type = 'stack';       %'separate' files or 'stack'
p.extension = '.nd2';   %'jpg', 'tiff' or '.nd2'

%naming conventions
p.nucleiName = 'nuclei';%raw nuclei channel name
p.netName = 'net';      %raw net channel name

%target channel paths
p.channels = {...
    p.nucleiName,...
    p.netName};

%image information
p.pixelSize = 300;      %pixel size, nm/pixel
p.bitDepth = 12;        %camera bit depth
p.imSizeX = 1344;       %x image size, pixels
p.imSizeY = 1024;       %y image size, pixels

%segmentation settings
p.method ='adaptive';   %global,adpative,Edge or Chan-Vese
p.sensitivity = 0.5;
p.iterations = 100;
p.minArea = 100;        %100 for 20x in test, use pixelsize to calculate in future versions
p.watershed = 1;        %optional watershed separation

%analysis settings
p.areaInc = 1.33;       %area increase definition
p.combineConnected = 1; %connect cells that share nuclei


%--------------------------------------------------------------------------
%% 1.2 Prepare data
%   Extract images from raw data files and sorts into folders for
%   processing. Place all stacks in the same folder first. After
%   files has been extracted, make sure all channels all labeled
%   correctly and are in the same subfolder.
%
%
%   function NQ_prepareData
%   inputs
%       folder:         path to raw data
%       targetDir:      path to target directory
%       p:              parameters
%       'preview':      true to preview lists
%       'type':         'separate' or 'stack'
%       'extension':    i.e '.jpg', '.tif' or '.nd2'
%
%   outputs
%        none


NQ_prepareData (p.folder, p.targetDir, p, 'preview', false, 'type', p.type, 'extension', p.extension);

%% 1.3 Convert images
%   Convert images to gray scale and uint16 format and saves them.
%
%   function NQ_convertImages
%   inputs
%       p:                 parameters
%       expFolder:         path to data folder



NQ_convertImages (p, p.targetDir);

%% 1.4 Create experiment lists
% top row will have experiment folder
% each column will have individual samples
%

%experiment folders
expFolders = getAllFolderPaths (p.targetDir);

%sample folders
for iExp = 1:numel(expFolders)
    expList{1,iExp} = expFolders{iExp};
    sampleFolders = getAllFolderPaths (expFolders{iExp});
    
    for iSample = 1:numel(sampleFolders)
        sampleList{iSample,iExp} = sampleFolders{iSample};
    end
    
end


%save sample lists
sampleList( cellfun(@isempty, sampleList) ) = {0};
T = cell2table(sampleList);

writetable(T,[p.targetDir filesep 'sampleList.csv']);
disp('sample list saved.');



%% Part II - Image segmentation and labeling

iExp    = 1;
iSample = 1;

%optional batch function
for iSample = 1:numel(sampleList(:,2))
    
    if sampleList{iSample,iExp}>0
        
        % 2.1 Segment images
        %   Segments images and saves them.
        %
        %   function NQ_segmentImages
        %   inputs
        %       p:                 parameters
        %       expFolder:         path to data folder
        
        
        
        NQ_segmentImages (p, sampleList{iSample,iExp});
        
        
        
        % 2.2 Label masks
        %   Labels masks and saves them.
        %
        %   function NQ_labelMasks
        %   inputs
        %       p:                 parameters
        %       expFolder:         path to data folder
        
        
        
        NQ_labelMasks (p, sampleList{iSample,iExp});
        
        
        % Part III - Analysis
        
        
        
        % 3.1 Acquire and analyze cell properties
        
        
        NQ_getCellProperties (p, sampleList{iSample,iExp});
        
        
    end
    
    disp('end of sample list.')
    
end




%% 3.2 Determine NET threshold


NQ_determineThreshold (p, [p.targetDir filesep p.controlPath]);


%% 3.3 Output stats


NQ_outputData (p, sampleList{iSample,iExp});


