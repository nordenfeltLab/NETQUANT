function [] = NQ_convertImages (paramsIn, targetDir)
% NQ_convertImages will load images and convert them to 8-bit grayscale.
%
% Part of NET-QUANT.
%
%
%
% Pontus Nordenfelt 02/2016

%get main folders
expFolders = getAllFolderPaths (targetDir);

p = paramsIn;

p.channels = {...
    p.nucleiName,...
    p.netName};



for iFolder = 1:length(expFolders)
    
    %get subdirectories of all samples
    subdirs = getAllFolders(expFolders{iFolder});
    
    
                
    for iSample = 1:length(subdirs)
        
        
        
        basefolder = [expFolders{iFolder} filesep subdirs{iSample}];
        disp(['reading images from: ' basefolder filesep 'raw_images']);
        currExpFolder=getAllFolderPaths([basefolder filesep 'raw_images']);
        
        %Set up the directories for converted images as sub-directories of the
        %output directory.
        for j = 1:numel(p.channels)
            
            %Create string for current directory
            currDir = [basefolder filesep 'images' filesep p.channels{j}];
            
            %Check/create directory
            mkClrDir(currDir);
            
        end
        
        h = waitbar(0,'Converting images...');
        for nChan=1:numel(p.channels)
            currFolder=cell2mat(currExpFolder(~cellfun(@isempty,regexp(currExpFolder,p.channels{nChan}))));
            
            if  ~isempty(currFolder)
                filePath=getAllFilePaths(currFolder,'.*');
                
                disp(['channel ' num2str(nChan)]);
                nImages = numel(filePath);
                myImages=zeros(p.imSizeY,p.imSizeX, nImages);
                
                
                for iImage = 1:numel(filePath)
                    %read images
                    currIm = imread(filePath{iImage});
                    
                    %convert rgb images if necessary
                    if strcmp(p.extension,'.jpg')
                        currIm = rgb2gray(currIm);
                    end
                    
                    %temporary fix
%                     %convert to correct bit depth
%                     maxBit1 = (2^16)-1;
%                     maxBit2 = (2^p.bitDepth)-1;
%                     currIm = uint16((maxBit1/maxBit2)*(double(currIm)));
%                     
                    %store in structure
                    myImages(:,:,iImage) = currIm;
                    
                    
                    %Write it to disk as .tif
                    imwrite(currIm,[basefolder filesep 'images' filesep p.channels{nChan} filesep p.channels{nChan} '_'...
                        num2str(iImage,['%0' num2str(floor(log10(nImages))+1) '.f']) '.tif' ]);
                    
                    waitbar(iImage/nImages);
                    fprintf('.');
                end
                
                %store images in structure
                ims.channels.(p.channels{nChan})=myImages;
                
                save ([basefolder filesep 'images' filesep 'ims.mat'],'ims');
                
                fprintf('\n');
                
            end
            
        end
        close(h);
    end
end

end

