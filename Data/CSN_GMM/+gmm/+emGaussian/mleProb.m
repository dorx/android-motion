function prob = mleProb(point, dist)
% mleProb(point, dist)
% Input:
%   point - A column vector giving the point to use.
%   dist - A cell array whose first element is a mean vector of the given
%          distribution, and whose second element is the covariance matrix
%          of the given distribution.
%
% Output:
%   prob - The probability of that point in this distribution.

prob = mvnpdf(point, dist{1}, dist{2});

end

