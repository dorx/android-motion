% Input filenames
filenames = {'bikejon.acsn', 'jonsitwork.acsn', 'jonwalk1.acsn', ...
             'jonwalk2.acsn', 'bike2.acsn', 'bike3.acsn', ...
             'jonpunching.acsn', 'jonwalk.acsn'};

% Categories files correspond to.  It is required that no category is
% skipped.
categories = [1, 2, 3, 3, 1, 1, 4, 3];

% Portion of data to use as test set, approximately.
test_size = .1;

% Size of each window and amount to slide.
windowSize = 2;
windowStep = .5;

% Number of Fourier coefficients to get
fourier_num = 10;

% Number of moments to get
moments_num = 3;

num_categories = max(categories);

% Cell array of one cell array per category.
category_points = cell(1, num_categories);
for i = 1 : num_categories
    category_points{i} = {};
end
dists = category_points;
test_category_points = category_points; % Test points


disp('Training...');
% Now we need to get the distribution for each category and count the
% number of points belonging to each category.
%
% First, transform the input data into features and place each featurized
% point in the proper category.
for i = 1 : length(filenames)
    filename = filenames{i};
    category = categories(i);
    rawData = load(filename, ' ');
    rawWindows = slidingWindows(rawData, windowSize, windowStep);
    rGrav = removeGravity(rawWindows);
    for j = 1 : length(rGrav)
        feat = features(rGrav{j}, fourier_num, moments_num);
        category_points{category} = [category_points{category} feat];
    end
end

% Remove test points.
for i = 1 : num_categories
    % Get indices of points to put in test set.
    points = category_points{i};
    total_points = length(points);
    test_indices = randsample(total_points, ...
                              round(test_size * total_points));
    % Separate points into train and test.
    category_points{i} = {};
    for j = 1 : total_points
        if sum(j == test_indices) == 1 % Check if test index
            test_category_points{i} = [test_category_points{i} points{j}];
        else
            category_points{i} = [category_points{i} points{j}];
        end
    end
end
    


% Count number of points in each category.
num_points = zeros(num_categories, 1);
for i = 1 : num_categories
    num_points(i) = length(category_points{i});
end
total_points = sum(num_points);

% Now assign weights.
weights = zeros(num_categories, 1);
for i = 1 : num_categories
    weights(i) = num_points(i) / total_points;
end

% Get distributions
for i = 1 : num_categories
    dists{i} = mleNormal(category_points{i});
end

% Test on input data.
disp('Testing');
num_right = 0;
% Go through each point and classify it.
for i = 1 : num_categories
    disp(i);
    for j = 1 : num_points(i)
        % Get point as a vector
        point = category_points{i}{j};
        point = point';
        point = point(:);
        % Classify point
        highest_prob = 0;
        predicted_category = 0;
        for k = 1 : num_categories
            prob = weights(k) * mvnpdf(point, dists{k}{1}, dists{k}{2});
            if prob > highest_prob
                highest_prob = prob;
                predicted_category = k;
            end
        end
        % Test accuracy
        if i == predicted_category
            num_right = num_right + 1;
        else
            %disp(['Thought ', num2str(i), ' was ', num2str(predicted_category)]);
        end
    end
end
disp(['In-Sample Accuracy: ', num2str(num_right / total_points)]);

% Test on test data.
num_right = 0;
total_test_points = 0;
for i = 1 : num_categories
    total_test_points = total_test_points + ...
                        length(test_category_points{i});
end

% If no test points, do nothing.
if (total_test_points == 0)
    return;
end

% Go through each point and classify it.
for i = 1 : num_categories
    disp(i);
    for j = 1 : length(test_category_points{i})
        % Get point as a vector
        point = test_category_points{i}{j};
        point = point';
        point = point(:);
        % Classify point
        highest_prob = 0;
        predicted_category = 0;
        for k = 1 : num_categories
            prob = weights(k) * mvnpdf(point, dists{k}{1}, dists{k}{2});
            if prob > highest_prob
                highest_prob = prob;
                predicted_category = k;
            end
        end
        % Test accuracy
        if i == predicted_category
            num_right = num_right + 1;
        else
            %disp(['Thought ', num2str(i), ' was ', num2str(predicted_category)]);
        end
    end
end
disp(['Out-of-Sample Accuracy: ', num2str(num_right / total_test_points)]);