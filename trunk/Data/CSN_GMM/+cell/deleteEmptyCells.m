function c = deleteEmptyCells(c)
% deleteEmptyCells - remove the empty cells from a cell array.
%   
% Input:
%   c - cell array, possibly with empty cells
%
% Output:
%   c - rank one cell array, without empty cells. I think this will be a
%   row vector.
%

import cell.*

% check input:
if ~iscell(c)
    error('deleteEmptyCells: c is not a cell array.')
end

c(cellfun(@isempty, c)) = [];

% assert that the output is the expected dimensionality:

end

