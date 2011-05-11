function prob = emProb(point, dists)
% mleProb(point, dist)
% Input:
%   point - A column vector giving the point to use.
%   dists - A cell array of cell arrays, where in each sub-cell array
%           the first element is a weight,          
%           the second element is a vector corresponding to
%           the mean of the input data and whose third element is the
%           covariance matrix of the input data.

% Number of Gaussians our overall distribution is a sum of
num_dists = length(dists);

% Add together the probabilities from each distribution
prob = 0;
for i = 1 : num_dists
    prob = prob + dists{i}{1} * mvnpdf(point, dists{i}{2}, dists{i}{3});
end

end

