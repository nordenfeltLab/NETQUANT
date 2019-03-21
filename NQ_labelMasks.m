function [] = NQ_labelMasks (paramsIn, expFolder)
% NQ_labelMasks will label masks and save them.
%
% Part of NET-QUANT.
%
%
%
% Pontus Nordenfelt 02/2016


%% ------ Parameters ------- %%
pString = 'label_'; %The string to prepend before the background mask directory & channel name
dName = 'labels';%String for naming the directory
p = paramsIn;


%% ------- Initialization------%%
[~, ims] = NQ_loadStruct(expFolder,'masks');

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

%% ------- Labeling------%%


h = waitbar(0,'Labeling images...');

for iChan = 1:nChan
    
    nImages = size(ims.channels.(p.channels{iChan}),3);
    outDir = [expFolder filesep dName filesep p.channels{iChan}];
    
   
    
    disp (['labeling images channel ' num2str(iChan)]);
    for iImage = 1:nImages
        
        currMask = ims.channels.(p.channels{iChan})(:,:,iImage);
        
        
        cc = bwconncomp(currMask);
        
        
        L = labelmatrix(cc);
        
        
        labels.channels.(p.channels{iChan})(:,:,iImage) = L;
        rgbLabel = label2rgb(L);
        
        fig1=figure('Visible','off');
        imshow(rgbLabel,[]);
        hold on
        
        
        %display numbers
        s = regionprops(L, 'Centroid');
        for k = 1:numel(s)
            c = s(k).Centroid;
            text(c(1), c(2), sprintf('%d', k), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', 'FontWeight', 'bold');
            
        end
        hold off
        
        %Write it to disk
        print(fig1,[outDir filesep pString num2str(iImage,...
            ['%0' num2str(floor(log10(nImages))+1) '.f']) '.jpeg' ],'-djpeg');
        
        close(fig1);
        
        waitbar(iImage/nImages);
        
        fprintf('.');
    end
    
    fprintf('\n');
end
close(h);
save ([expFolder filesep dName filesep 'labels.mat'],'labels');

%set flags and save metadata
metadata.flags.NQ_labelImages = 1;

save([expFolder filesep 'NQ_metadata.mat'],'metadata'); 


end