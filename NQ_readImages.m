function [ images ] = NQ_readImages ( expFolder, channels, paramsIn )
%NQ_readImages Reads images processed using the NET-QUANT software
%   

p = paramsIn;

disp(['reading images from: ' expFolder]);

currExpFolder=getAllFolderPaths(expFolder);

for nChan=1:numel(channels)
    currFolder=cell2mat(currExpFolder(~cellfun(@isempty,regexp(currExpFolder,channels{nChan}))));
    
    if  ~isempty(currFolder)
        filePath=getAllFilePaths(currFolder,'.tif');
        
        disp(['channel ' num2str(nChan)]);
        nImages = numel(filePath);
        myImages=zeros(p.imSizeY, p.imSizeX, nImages);
        
     
        for iImage = 1:numel(filePath)
            %read images
            myImages(:,:,iImage) = imread(filePath{iImage});
            fprintf('.');
            
            %store images in structure
            images.channels.(channels{nChan})=myImages;
            
        end
        fprintf('\n');
        
    end
    
end

end
