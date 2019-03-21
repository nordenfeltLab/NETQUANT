function [] = NQ_segmentImages (paramsIn, expFolder)
% NQ_segmentImages will segment multiple images using the NQ_segmentImage function
% and save them.
%
% Part of NET-QUANT.
%
%
%
% Pontus Nordenfelt 02/2016


%% ------ Parameters ------- %%
pString = 'mask_'; %The string to prepend before the background mask directory & channel name
dName = 'masks';%String for naming the directory
p = paramsIn;


%% ------- Initialization------%%

[~, ims] = NQ_loadStruct(expFolder,'ims'); %load images

load([expFolder filesep 'NQ_metadata.mat']); %load metadata

p.channels = {...
    p.nucleiName,...
    p.netName};

nChan = numel(p.channels);

%Set up the directories for segmented images as sub-directories of the
%output directory.
for j = 1:numel(p.channels)
    
    %Create string for current directory
    currDir = [expFolder filesep dName filesep p.channels{j}];
    
    %Check/create directory
    mkClrDir(currDir);
    
end

%% ------- Segmentation------%%
h = waitbar(0,'Segmenting images...');

for iChan = 1:nChan
    
    nImages = size(ims.channels.(p.channels{iChan}),3);
    outDir = [expFolder filesep dName filesep p.channels{iChan}];
    
    
    
    disp (['segmenting images channel ' num2str(iChan)]);
    for iImage = 1:nImages
        
        currIm = ims.channels.(p.channels{iChan})(:,:,iImage);
        
        [mask,~] = NQ_segmentImage(p, currIm, p.method{iChan}, p.sensitivity{iChan}, p.iterations{iChan}, p.minArea{iChan}, p.watershedOn{iChan});
        
        masks.channels.(p.channels{iChan})(:,:,iImage) = mask;
        
        %Write it to disk
        imwrite(mask,[outDir filesep pString num2str(iImage,...
            ['%0' num2str(floor(log10(nImages))+1) '.f']) '.tif' ]);
        fprintf('.');
        
        waitbar(iImage/nImages);
    end
    
    fprintf('\n');
end
close(h);
save ([expFolder filesep dName filesep 'masks.mat'],'masks');

%set flags and save metadata
metadata.flags.NQ_segmentImages = 1;

save([expFolder filesep 'NQ_metadata.mat'],'metadata'); 

end