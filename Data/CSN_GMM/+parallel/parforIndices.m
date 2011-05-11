function [ index ] = parforIndices( ranges, i )
%PARFORINDICES Maps integers to indices into a multidimensional array
%   
% INPUTS:
%   ranges - (1xn) vector of positive integer values, e.g. [1,2,3]
%   specifies a 1x2x3 matrix.
%   i - specifies i^{th} element in the multidimensional array to find an
%       index for.
% OUTPUTS:
%   index - (1xn) vector of positive integer values

[m,n] = size(ranges);
assert(m==1); 
assert(n>=1);
maxIndex = prod(ranges);
assert(i>0);
assert(i<=maxIndex); %uncomment this to allow wrap around


index = zeros(1,n);
previousTerms = 1;
for k=0:n-1
    r = ranges(k+1);
    index(k+1) = ceil(mod( floor((i-1)/previousTerms),r))+1;
    previousTerms = previousTerms*r;
end

end
