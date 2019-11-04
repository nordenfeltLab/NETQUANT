function [filePath] = getAllFilePaths(dirName, pattern)
% getAllFilePaths returns full filepaths from specified directory 
%
%
% Pontus Nordenfelt 2013

dirData = dir(dirName);      % Get the data for the current directory
dirIndex = [dirData.isdir];  % Find the index for directories
filePath = {dirData(~dirIndex).name}';  % Get a list of the files

%sort files by creation date
[~,dateIndex] = sort([dirData(~dirIndex).datenum]);
filePath = filePath(dateIndex);

if ~isempty(filePath)
    matchstart = regexpi(filePath, pattern);
    filePath = filePath(~cellfun(@isempty, matchstart));
    filePath = cellfun(@(x) fullfile(dirName,x),...  % Prepend path to files
        filePath,'UniformOutput',false);
end


%continue with subdirectories
subDirs = {dirData(dirIndex).name};  % Get a list of the subdirectories
validIndex = ~ismember(subDirs,{'.','..'});  % Find index of subdirectories
%   that are not '.' or '..'
for iDir = find(validIndex)                  % Loop over valid subdirectories
    nextDir = fullfile(dirName,subDirs{iDir});    % Get the subdirectory path
    filePath = [filePath; getAllFilePaths(nextDir, pattern)];  % Recursively call getAllFiles
end

end