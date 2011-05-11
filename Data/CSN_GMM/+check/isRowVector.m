function [ bool ] = isRowVector( X )
% isRowVector - check if X is a rowvector.
%   Returns true if X is a row vector, a scalar, or is empty
%
import check.*

bool = isColumnVector(X');

end