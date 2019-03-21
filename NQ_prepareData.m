function [] = NQ_prepareData (folder, targetDir, paramsIn,  varargin)
% NQ_prepareData will extract metadata and organize raw images, either if
% they are already separate or as multichannel files.
% Images in folder dir will be copied to target dir with basename as dir
% name and images sorted into different channels.
%
% Part of NET-QUANT.
%
%
%
% Pontus Nordenfelt 10/2016, 06/2018

%% inputs
ip = inputParser;

ip.addParamValue ('preview', false, @islogical);
ip.addParamValue ('type', 'stack', @ischar); %stack or separate
ip.addParamValue ('extension','.nd2', @ischar);
ip.parse (varargin{:});
inputs = ip.Results;

p = paramsIn;

%% initialize
foldernames = getAllFolders(folder);
disp('will create folders:');
disp(foldernames);

if inputs.preview == false
    
    switch inputs.type
        case 'separate'
            
            h = waitbar(0,'Preparing data...');
            
            %% copy and sort images into channels
            
            channels={...
                p.nucleiName,...
                p.netName};
            
            saveFolders={...
                ['raw_images' filesep 'dna'],...
                ['raw_images' filesep 'net']};
            
            %% copy images to channel folders
            
            filePath = [];
            %get original filenames
            for i=1:numel(foldernames)
                
                for k=1:numel(channels)
                    %get original image filenames
                    filenames{i} = getAllFileNames([folder filesep foldernames{i} filesep channels{k}],...
                        p.extension);
                    %get full path of images
                    filepaths = getAllFilePaths([folder filesep foldernames{i} filesep channels{k}],...
                        p.extension);
                    filePath = [filePath; filepaths];
                end
            end
            
            
            %take filepath list and replace sample base with result base
            targetPath = cell(numel(filePath),1); %strrep(filePath,folder,targetDir);
            
            im=1;
            for i=1:numel(foldernames)
                filenameList = filenames{1,i};
                for k=1:numel(channels)
                    for j=1:numel(filenameList)
                        
                        %modify list to add "raw_images" folder
                        %targetPath = strrep(targetPath,[filesep foldernames{i} filesep],[filesep foldernames{i} filesep filenameList{j} saveFolders{1} filesep]);
                        %targetPath = strrep(targetPath,[filesep foldernames{i} filesep],[filesep foldernames{i} filesep filenameList{j} saveFolders{2} filesep]);
                        
                        targetPath{im} = [targetDir filesep foldernames{i} filesep filenameList{j} filesep saveFolders{k} filesep filenameList{j}];
                        %check if folder exists otherwise make it
                        
                        destination = fileparts(targetPath{im});
                        
                        if ~exist(destination,'dir')
                            mkdir(destination);
                        end
                        
                        
                        %                     targetPath{im+1} = [targetDir filesep foldernames{i} filesep filenameList{j} filesep saveFolders{2} filesep filenameList{j}];
                        %
                        %                     %check if folder exists otherwise make it
                        %
                        %                         destination = fileparts(targetPath{im+1});
                        %
                        %                         if ~exist(destination,'dir')
                        %                             mkdir(destination);
                        %                         end
                        %
                        
                        im = im +1;
                        
                        
                        %store parameter information to result folder
                        metadata = p;
                        metadata.flags.NQ_prepareData = 1; %set flags
                        save([targetDir filesep foldernames{i} filesep filenameList{j} filesep 'NQ_metadata.mat'],'metadata'); %save file
                    end
                    
                end
            end
            
            
            
            
            
            %copy the original images to results folder
            cellfun(@copyfile,filePath,targetPath);
            
            
            
            %end
            
            %end
            
            %waitbar(i/numel(foldernames));
            %end
            %             %get original filenames
            %             for i=1:numel(foldernames)
            %
            %                 for k=1:numel(channels)
            %                     %get original image filenames
            %                     filenames = getAllFileNames([folder filesep foldernames{i} filesep channels{k}],...
            %                         p.extension);
            %                     %get full path of images
            %                     filePath = getAllFilePaths([folder filesep foldernames{i} filesep channels{k}],...
            %                         p.extension);
            %
            %                     for j=1:numel(filenames)
            %                         %specify save path
            %                         destination=[targetDir filesep foldernames{i} filesep filenames{j} filesep saveFolders{k}];
            %
            %                         if ~exist(destination,'dir')
            %                             mkdir(destination);
            %                         end
            %                         %pre-allocate with save path
            %                         targetPath = repmat({destination},length(filePath),1);
            %
            %                         %list all original image names with full destination path
            %                         for im = 1:numel(filenames)
            %                             targetPath{im} = [targetPath{im} filesep filenames{im}];
            %                         end
            %
            %                         %copy the original images to results folder
            %                         cellfun(@copyfile,filePath,targetPath);
            %
            %                         %store parameter information to result folder
            %                         metadata = p;
            %                         metadata.flags.NQ_prepareData = 1; %set flags
            %                         save([targetDir filesep foldernames{i} filesep filenames{j} filesep 'NQ_metadata.mat'],'metadata'); %save file
            %
            %                     end
            %
            %                 end
            %
            %                     %waitbar(i/numel(foldernames));
            %             end
            
        case 'stack'
            
            h = waitbar(0,'Preparing data...');
            
            %loop over conditions
            
            for iFolder = 1:numel(foldernames)
                
                currfolder = [folder filesep foldernames{iFolder}];
                % find basename
                filenames = getAllFileNames(currfolder,inputs.extension);
                
                %remove extension
                %foldernames = cellfun(@(x) x(1:end-length(inputs.extension)),filenames,'UniformOutput',false);
                
                channels={...
                    p.nucleiName,...
                    p.netName};
                
                
                for iFile = 1:numel(filenames)
                    
                    %read .nd file
                    imData = bfopen ([currfolder filesep filenames{iFile}]);
                    
                    %get metadata
                    omeMeta = imData{1, 4};
                    
                    %extract individual images and save to channel folders
                    try
                        p.imSizeX   = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
                        p.imSizeY   = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
                    catch
                        warndlg ('could not extract image size, using manual entered information','Error');
                    end
                    
                    p.nChan     = omeMeta.getPixelsSizeC(0).getValue(); % channels
                    p.nTime     = omeMeta.getPixelsSizeT(0).getValue(); % time points / positions
                    %p.nPlane    = omeMeta.getPixelsSizeZ(0).getValue(); %
                    %z planes are not supported
                    
                    %determine images in whole stack
                    nIm = p.nTime*p.nChan;
                    
                    
                    for iChan = 1:p.nChan
                        
                        %create output directories
                        outDir = [targetDir filesep foldernames{iFolder} filesep filenames{iFile} filesep 'raw_images' filesep (channels{iChan})];
                        if ~exist(outDir,'dir')
                            mkdir(outDir)
                        end
                        
                        name = filenames{iFile}(1:end-length(inputs.extension));
                        
                        iTime=1;
                        for iIm = iChan:p.nChan:nIm
                            
                            bfsave(imData{1,1}{iIm,1},[outDir filesep name '_'...
                                num2str(iTime,['%0' num2str(floor(log10(p.nTime))+1) '.f']) '.tif' ]);
                            iTime=iTime+1;
                            
                            waitbar(iIm/nIm);
                            
                        end
                        
                        %store parameter information to result folder
                        metadata = p;
                        metadata.flags.NQ_prepareData = 1; %set flags
                        save([targetDir filesep foldernames{iFolder} filesep filenames{iFile} filesep 'NQ_metadata.mat'],'metadata'); %save file
                        
                        
                    end
                end
                
            end
            
    end
    
end
close(h);
disp('Image data has been prepared for processing.');
end

