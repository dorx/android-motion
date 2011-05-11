function  sacDirToCsv( sacDir)
%   sacDirToCsv - convert all SAC files in a directory to CSV format, and
%   output to another directory.
%
% Input:
%   sacDir - path to a directory of SAC files
%   outDir - output directory. If it does not exist, it will be created.
%

import sac.*
import sac.sacCsv.*
import check.*


% 
% if ~isDirectory(outDir)
%     disp(['Creating ' outDir]);
%     mkdir(outDir);
% end

if nargin == 0
    sacDir = uigetdir();
end

assertDirectory(sacDir);

% get the names of all files. dirListing is a struct array.
dirListing = dir(sacDir);

% loop through the files and open. dir also lists the
% directories, so you have to check for them.
for d = 1:length(dirListing)
    if ~dirListing(d).isdir
        fileName = fullfile(sacDir,dirListing(d).name); % use full path because the folder may not be the active path
        
        if isFile(fileName, 'sac')
            %name = [outDir '/' dirListing(d).name];
            name = dirListing(d).name;
            sacToCsv( fileName, name);
        end
    end
end


end