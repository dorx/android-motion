function [ bool ] = isColumnVector( X )
% isColumnVector - check if X is a column vector.
%   Returns tru if X is a column vector, a scalar, or is empty

if isempty(X) % empty is a column
    bool = true;
    return
end

if isscalar(X) % scalar is a column
    bool = true;
    return
end

[~,n] = size(X);

if n == 1
    bool = true;
    return
end

bool = false;
return

end

