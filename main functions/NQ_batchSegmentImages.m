function [] = NQ_batchSegmentImages (paramsIn, expFolder)
% NQ_segmentImages will segment images and save the masks.
%
% Part of NET-QUANT.
%
%
%
% Pontus Nordenfelt 11/2016


%% ------ Parameters ------- %%
pString = 'mask_'; %The string to prepend before the background mask directory & channel name
dName = 'masks';%String for naming the directory
p = paramsIn;


%% ------- Initialization------%%
%Load images from prepared image structure file
[~, ims] = NQ_loadStruct(expFolder,'ims');

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

%Batch segmentation using the NQ_segmentImage function

for iChan = 1:nChan
    
    nImages = size(ims.channels.(p.channels{iChan}),3);
    outDir = [expFolder filesep dName filesep p.channels{iChan}];
    
    disp (['segmenting images channel ' num2str(iChan)]);
    for iImage = 1:nImages
        
        currIm = ims.channels.(p.channels{iChan})(:,:,iImage);
        
        [mask,~] = NQ_segmentImage(currIm, p.method, p.iterations, p.minArea);
        
        masks.channels.(p.channels{iChan})(:,:,iImage) = mask;
        
        %Write it to disk
        imwrite(mask,[outDir filesep pString num2str(iImage,...
            ['%0' num2str(floor(log10(nImages))+1) '.f']) '.tif' ]);
        fprintf('.');
    end
    
    fprintf('\n');
end

save ([expFolder filesep dName filesep 'masks.mat'],'masks');


end