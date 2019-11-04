function [fileName] = getAllFileNames(dirName, pattern)
% getAllFileNames returns filenames from specified directory 
%
%
% Pontus Nordenfelt 2013

dirData = dir(dirName);      % Get the data for the current directory
dirIndex = [dirData.isdir];  % Find the index for directories
fileName = {dirData(~dirIndex).name}';  % Get a list of the files
if ~isempty(fileName)
    matchstart = regexpi(fileName, pattern);
    fileName = fileName(~cellfun(@isempty, matchstart));
end

subDirs = {dirData(dirIndex).name};  % Get a list of the subdirectories
validIndex = ~ismember(subDirs,{'.','..'});  % Find index of subdirectories
%   that are not '.' or '..'
for iDir = find(validIndex)                  % Loop over valid subdirectories
    nextDir = fullfile(dirName,subDirs{iDir});    % Get the subdirectory path
    fileName = [fileName; getAllFileNames(nextDir, pattern)];  % Recursively call getAllFiles
end

end