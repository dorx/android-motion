function [ cFiles, cNames ] = listFiles( dirName, extension )
% listFiles - list all files in a directory
%
% Input:
%   dirName - path to a directory
%   extension - (optional) return only files of this extension. No '.'
%
% Output:
%   cFiles - column cell array of full paths of files
%   cNames - column cell array of pathless file names
%
% author: Matt Faulkner
%
import file.*
import check.*

assertDirectory(dirName);

% TODO:check that if an extension is specified, that it doesn't have a
% leading '.'


% get the names of all files. dirListing is a struct array.
dirListing = dir(dirName);

cFiles = cell(length(dirListing),1);
cNames = cell(length(dirListing),1);

% loop through the files and open. dir also lists the
% directories, so you have to check for them.
for d = 1:length(dirListing)
    if ~dirListing(d).isdir
        fileName = fullfile(dirName,dirListing(d).name); % use full path because the folder may not be the active path
        name = dirListing(d).name; % just the pathless name
        %
        if nargin == 2
            % check for file extension
            if isFile(fileName, extension)
                cFiles{d} = fileName; % full file path
                cNames{d} = name; % just name
            end
        else
            % just check if its a file
            if isFile(fileName)
                cFiles{d} = fileName;
                cNames{d} = name;
            end
        end
        %
    end
end

%Remove empty cells, e.g. listings that were directories and skipped over.
cFiles(cellfun(@isempty, cFiles)) = [];
cNames(cellfun(@isempty, cNames)) = [];

end

