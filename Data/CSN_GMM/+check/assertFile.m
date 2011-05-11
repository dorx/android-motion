function assertFile( fileName, extension )
% assertFile - throw an error if not a file
%
% Input:
%   fileName
%   extension - optional extension
%
%
import check.*

if nargin == 1
    bool = isFile(fileName);
    if ~bool
        error([fileName ' cannot be found or is not a file.'])
    end
else
    bool = isFile(fileName, extension);
    if ~bool
        error([fileName ' cannot be found or is not an ' extension ' file.'])
    end
end



end

