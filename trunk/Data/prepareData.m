clear all; % cleans up all variables
close all; % closes all figures
clc; % clean up the command window too

possibleActs = ['walking   ';
                'running   ';
                %'sitting   ';
                'idling    ';
                'upstairs  ';
                'downstairs';
                'biking    '];

load('C:/Users/AlexFandrianto/Documents/MATLAB/CS141/BackProp/ReducedData/data_Alex_red3.mat');

TRAIN = cell(6, 1);
TEST = cell(6, 1);

% Now you have the C cell of 6 activities.
for i=1:length(possibleActs(:, 1))
    data = C{i};
    indexing = randperm(length(data(:, 1)));
    
    half = int32(length(data)/2);
    a = indexing(1:half);
    b = indexing(half+1:length(indexing));
    
    training = zeros(half, length(data(1, :)));
    testing = zeros(length(data) - half, length(data(1, :)));
    for k=1:half
        j = a(k);
        training(k, :) = data(j, :);
    end
    for k=half+1:length(data)
        j = b(k - half);
        testing(k - half, :) = data(j, :);
    end
    TRAIN{i} = training;
    TEST{i} = testing;
end

save('C:/Users/AlexFandrianto/Documents/MATLAB/CS141/BackProp/ReducedData/data_Alex_red3_learnable.mat', 'C', 'TRAIN', 'TEST');