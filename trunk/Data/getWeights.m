function [ weights ] = getWeights()
%getWeights Takes the data_Alex_red3_learnable file, which has
%   the pre-reduced data and finds the weight matrices.
%   weights is an array containing all the different 
%   weight matrices for the comparisons
%   TEST and TRAIN have the data for walking, running, idling,
%   upstairs, downstairs, and biking, in that order
%   So the weight matrix will give the comparisons in order 
%   (walk, run, idle, up, down, bike) vs. (walk, run, idle, up, down, bike)
%   from left to right

load('/Users/Robert/android-motion/Data/ReducedData/data_Alex_red3_learnable.mat');
% Loads C TEST and TRAIN
weights = cell(6, 6, 3);
n=1;
for i=1:6
    for j=1:6
        % Iterate through all combinations except self x self
        if i==j
            continue
        end
        n % keep track of what iteration we're on
        
        train = [TRAIN{i} ; TRAIN{j}];
        trainvalues = [ones(length(TRAIN{i}(:, 1)), 1) ; 0 * ones(length(TRAIN{j}(:, 1)), 1)];
        test = [TEST{i} ; TEST{j}];
        testvalues = [ones(length(TEST{i}(:, 1)), 1) ; 0 * ones(length(TEST{j}(:, 1)), 1)];
        % Turn TEST and TRAIN into the matrices we need for backProp3Layer
        
        [w1, w2, w3] = ...
            backProp3Layer(train, trainvalues, test, testvalues, 5, 5, 1000, .1);
        % Get weight matrices with backProp3Layer
        
        weights{i, j, 1} = w1;
        weights{i, j, 2} = w2;
        weights{i, j, 3} = w3;
        % Add to weights matrix

        n = n+1;
        % increment n
    end
end


end

