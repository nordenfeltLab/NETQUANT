function [metadata] = NQ_loadImageInfo (folder, varargin)
% NQ_loadImageInfo will extract metadata of first image
% in data set.
% Part of NET-QUANT.
%
%
%
% Pontus Nordenfelt 03/2017, 06/2018

%% inputs
ip = inputParser;

ip.addParamValue ('type', 'stack', @ischar); %stack or separate
ip.addParamValue ('extension','.nd2', @ischar); %file extension
ip.addParamValue ('controlName','control', @ischar); %name of control folder
ip.addParamValue ('DNAChannelName','dna', @ischar); %name of dna channel folder
ip.parse (varargin{:});
inputs = ip.Results;


%% check for control folder
if ~strcmp(inputs.controlName,'control')
    warndlg ('must have a folder named control','Error');
end


% select separate images or stack
switch inputs.type
    case 'separate'
        
        
        % initialize
        
        %set folder
        currfolder = [folder filesep inputs.controlName filesep inputs.DNAChannelName];
        
        
        %find basename
        filenames = getAllFileNames(currfolder,inputs.extension);
        
        % check for image
        if isempty(filenames)
            warndlg (['can not find image in ' currfolder],'Error');
        end
        
        
        %read first file
        imData = bfopen ([currfolder filesep filenames{1}]);
        
        
        
        % get metadata
        omeMeta = imData{1, 4};
        
        try
            metadata.imSizeX   = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
            metadata.imSizeY   = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
        catch
            metadata.imSizeX   = 0;
            metadata.imSizeY   = 0;
            warndlg ('could not extract image size, please update manually','Error');
        end
        %metadata.nPlane    = omeMeta.getPixelsSizeZ(0).getValue(); % z planes
        %metadata.nChan     = omeMeta.getPixelsSizeC(0).getValue(); % channels
        %metadata.nTime     = omeMeta.getPixelsSizeT(0).getValue(); % time points
        try
            metadata.bitDepth = double(omeMeta.getPixelsSignificantBits(0).getNumberValue);
        catch
            metadata.bitDepth = 0;
            warndlg ('could not extract bit depth, please update manually','Error');
        end
        
        %pixel dimensions
        try
            metadata.pixelSizeX = double(omeMeta.getPixelsPhysicalSizeX(0).value);
            metadata.pixelSizeY = double(omeMeta.getPixelsPhysicalSizeY(0).value);
        catch
            metadata.pixelSizeX = 0;
            metadata.pixelSizeY = 0;
            warndlg ('could not extract pixel size, please update manually','Error');
        end
        
        %channel names, setting default names when using single images
        metadata.channelName_1 = 'dna'; %char(omeMeta.getChannelName(0,0).string);
        metadata.channelName_2 = 'net'; %char(omeMeta.getChannelName(0,1).string);
        
        
    case 'stack'
        %% initialize
        
        
        currfolder = [folder filesep inputs.controlName];
        %find basename
        filenames = getAllFileNames(currfolder,inputs.extension);
        
        % check for image
        if isempty(filenames)
            warndlg (['can not find image of specified type in ' currfolder],'Error');
        end
        
        
        %read first file
        imData = bfopen ([currfolder filesep filenames{1}]);
        
        %% get metadata
        omeMeta = imData{1, 4};
        
        try
            metadata.imSizeX   = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
            metadata.imSizeY   = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
        catch
            metadata.imSizeX   = 0;
            metadata.imSizeY   = 0;
            warndlg ('could not extract image size, please update manually','Error');
        end
        %metadata.nPlane    = omeMeta.getPixelsSizeZ(0).getValue(); % z planes
        %metadata.nChan     = omeMeta.getPixelsSizeC(0).getValue(); % channels
        %metadata.nTime     = omeMeta.getPixelsSizeT(0).getValue(); % time points
        try
            metadata.bitDepth = double(omeMeta.getPixelsSignificantBits(0).getNumberValue);
        catch
            metadata.bitDepth = 0;
            warndlg ('could not extract bit depth, please update manually','Error');
        end
        %pixel dimensions
        try
            metadata.pixelSizeX = double(omeMeta.getPixelsPhysicalSizeX(0).value);
            metadata.pixelSizeY = double(omeMeta.getPixelsPhysicalSizeY(0).value);
        catch
            metadata.pixelSizeX = 0;
            metadata.pixelSizeY = 0;
            warndlg ('could not extract pixel size, please update manually','Error');
        end
        
        %channel names
        try
            metadata.channelName_1 = char(omeMeta.getChannelName(0,0).string);
            metadata.channelName_2 = char(omeMeta.getChannelName(0,1).string);
        catch
            %channel names, setting default names when not finding names
            metadata.channelName_1 = 'dna';
            metadata.channelName_2 = 'net';
            warndlg ('could not extract channel names, setting default names','Error');
        end
        
end
end
