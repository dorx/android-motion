function dists = emGaussian(data, n)
% emGaussian(data, n)
% Input:
%   data - A (non-empty) cell array of all points for a particular class
%          of activities.
%   n - Number of Gaussians to use.
%
% Output:
%   dists - A cell array of cell arrays, where in each sub-cell array
%           the first element is a weight,          
%           the second element is a vector corresponding to
%           the mean of the input data and whose third element is the
%           covariance matrix of the input data.

% Number of points in the data set
num_points = length(data);

% Number of variables in each data point
num_vars = numel(data{1});

% Cell array of three cell arrays per category, where we define a category
% to be one of the Gaussians contributing to this mixture model.
category = {{} {} {}};
categories = cell(1, n);
for i = 1 : n
    categories{i} = category;
end

% Initialize means to 0 and covariance to be independent with random std
for i = 1 : n
    categories{i}{1} = 1 / n; % Distributions initiall equally likely
    categories{i}{2} = rand(num_vars, 1);%zeros(num_vars, 1);
    categories{i}{3} = diag(rand(num_vars, 1), 0) + .5 * diag(ones(num_vars,1));
end

% Need to store new values
new_categories = categories;

% Also need to store posterior probabilities, one probability per point
% per category
posteriors = cell(1, n);
for i = 1 : n
    posteriors{i} = zeros(1, num_points);
end

% Do EM.  the number is arbitrary, for now
% TODO: Test for convergence so that we can stop early
for iter = 1 : 10
    % Get posteriors
    for j = 1 : num_points
        point = data{j};
        % First, calculate denominator of each posterior, which doesn't
        % depend on the category
        denom = 0;
        % Calculate minimum exponenent.  We need this to avoid numerical
        % issues.
        min_exponent = .5 * (point - categories{1}{2})' / ...
                categories{1}{3} * (point - categories{1}{2});
        for cat = 1 : n
            exponent = .5 * (point - categories{cat}{2})' / ...
                categories{cat}{3} * (point - categories{cat}{2});
            min_exponent = min(min_exponent, exponent);
        end
        %disp(['min exponent ', num2str(min_exponent)]);
        for cat = 1 : n
            % Calculate power in exponent of mvnpdf
            exponent = -.5 * (point - categories{cat}{2})' / ...
                categories{cat}{3} * (point - categories{cat}{2}) + ...
                min_exponent;
            coeff = 1 / ((2 * pi) ^ (num_vars / 2) * sqrt(det(categories{cat}{3})));
            
            denom = denom + categories{cat}{1} * coeff * exp(exponent);
            
            
            %denom = denom + categories{cat}{1} * ...
            %    mvnpdf(point, categories{cat}{2}, categories{cat}{3});
        end
        % Now, calculate the numerator and set the posteriors
        for cat = 1 : n
            exponent = -.5 * (point - categories{cat}{2})' / ...
                categories{cat}{3} * (point - categories{cat}{2}) + ...
                min_exponent;
            coeff = 1 / ((2 * pi) ^ (num_vars / 2) * sqrt(det(categories{cat}{3})));
            numerator = categories{cat}{1} * coeff * exp(exponent);
            %numerator = categories{cat}{1} * ...
            %    mvnpdf(point, categories{cat}{2}, categories{cat}{3});
            posteriors{cat}(j) = numerator / denom;
        end
    end


    % Calculate new weights, means, and covariances
    for cat = 1 : n
        posterior_sum = sum(posteriors{cat});
        % New weight
        new_categories{cat}{1} = posterior_sum / num_points;
        
        % Calculate sums in the numerators of formulas for new mean and
        % covariance.
        mean_sum = zeros(num_vars, 1);
        cov_sum = zeros(num_vars, num_vars);
        for j = 1 : num_points
            point = data{j};
            mean_sum = mean_sum + posteriors{cat}(j) * point;
            cov_sum = cov_sum + posteriors{cat}(j) * ...
                (point - categories{cat}{2}) * ...
                (point - categories{cat}{2})';
        end
        
        % Get means and covariances
        new_categories{cat}{2} = mean_sum / posterior_sum;
        new_categories{cat}{3} = cov_sum / posterior_sum;
        
        % We require that every variable has variance > 0, so corrupt
        % the matrix very slightly
        covMat = new_categories{cat}{3};
        min_entry = max(abs(covMat(:)));
        for i = 1 : num_vars
            for j = 1 : num_vars
                if 0 < abs(covMat(i, j)) && abs(covMat(i, j)) < min_entry
                    min_entry = abs(covMat(i, j));
                end
            end
        end
        % Corrupt matrix slightly.  TODO: Maybe use min_entry for this
        alpha = .01;
        covMat = (1 - alpha) * covMat + alpha * eye(num_vars);

        new_categories{cat}{3} = covMat;
    end
    % Update categories
    categories = new_categories;
end

dists = categories;
end
