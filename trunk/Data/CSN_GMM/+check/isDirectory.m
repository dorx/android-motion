function [ bool ] = isDirectory( d )
% isDirectory - returns true if d is the path to a directory
%   
% Input:
%   d - String. Path to a potential directory.

if (exist(d,'file') == 7) % 7 means directory, obviously.
    bool = true;
else
    bool = false;
end

end

