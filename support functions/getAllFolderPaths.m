function [folders] = getAllFolderPaths(dirName)
% getAllFolderPaths returns full paths from specified directory 
%
%
% Pontus Nordenfelt 2013

dirData = dir(dirName);      % Get the data for the current directory
dirIndex = [dirData.isdir];  % Find the index for directories
subDirs = {dirData(dirIndex).name};  % Get a list of the subdirectories
validIndex = ~ismember(subDirs,{'.','..'});  % Find index of subdirectories
%   that are not '.' or '..'
folders=subDirs(validIndex)';
folders = cellfun(@(x) fullfile(dirName,x),...  % Prepend path to files
        folders,'UniformOutput',false);
end