function dist = mleNormal(data)
% mleNormal(data)
% Input:
%   data - A (non-empty) cell array of all points for a particular class
%          of activities.
%
% Output:
%   dist - A cell array whose first element is a vector corresponding to
%          the mean of the input data and whose second element is the
%          covariance matrix of the input data.

% Number of points in the data set
num_points = length(data);

% Number of variables in each data point
num_vars = numel(data{1});

% Get the mean vector
meanVec = zeros(num_vars, 1);
for i = 1 : num_points
    point = data{i};
    meanVec = meanVec + point;
end
meanVec = meanVec / num_points;

% Get the covariance matrix
covMat = zeros(num_vars);
for i = 1 : num_points
    point = data{i} - meanVec;
    covMat = covMat + point * point';
end
covMat = covMat / num_points;

% We require that every variable has variance > 0, so if there are entries
% with variance equal to zero, artificially increase them by a small
% amount.  Do this by increasing the variance of every variable by a small
% amount.
min_entry = max(abs(covMat(:)));
for i = 1 : num_vars
    for j = 1 : num_vars
        if 0 < abs(covMat(i, j)) && abs(covMat(i, j)) < min_entry
            min_entry = abs(covMat(i, j));
        end
    end
end

for i = 1 : num_vars
    covMat(i, i) = covMat(i, i) + min_entry / 100;
end


% Stick into a cell array
dist = {meanVec, covMat};

end