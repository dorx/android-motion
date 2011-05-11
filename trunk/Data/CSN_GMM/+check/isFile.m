function [ bool ] = isFile( s, extension )
% isFile - returns true if s is the path to a file. The file must have the
% needed extension, if specified.
%
% Inputs:
%   s - string 
%   extension - string, without '.'

import java.lang.String


if (exist(s,'file') ~= 2)
    bool = false;
    return;
end

if nargin == 2

    S = String(s);
    S = S.toLowerCase();
    Extension = String(extension);
    Extension = Extension.toLowerCase();
    
    if ~S.endsWith(Extension)
        bool = false;
        return
    end

end

bool = true;

end

