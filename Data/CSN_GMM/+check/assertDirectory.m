function assertDirectory( dirName )
% assertDirectory - throw an error if the specified string is not the path
% to a directory
%   
% author: Matt Faulkner
%
import check.*

if ~isDirectory(dirName)
    error([ dirName ' cannot be found or is not a directory'])
end

end

