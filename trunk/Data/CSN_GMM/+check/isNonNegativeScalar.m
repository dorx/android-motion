function [ bool ] = isNonNegativeScalar( x )
% isNonNegativeScalar

if ~isscalar(x)
    bool = false;
    return
end

if x < 0
    bool = false;
    return
end

bool = true;


end



