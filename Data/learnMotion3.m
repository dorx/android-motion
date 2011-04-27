clear all; % cleans up all variables
close all; % closes all figures
clc; % clean up the command window too

A = load('C:\Users\AlexFandrianto\Documents\MATLAB\CS141\BackProp\Data\Alex_running_04051515.acsn');
B = load('C:\Users\AlexFandrianto\Documents\MATLAB\CS141\BackProp\Data\Alex_walking_04051545.acsn');

data = zeros(40, 3);
values = zeros(40, 1);

data(1:20, :) = reduction1(A, 20, 3, 650, 100);
data(21:40, :) = reduction1(B, 20, 3, 650, 100);
values(1:20, :) = 1;

dataTest = zeros(100, 3);
valuesTest = zeros(100, 1);

dataTest(1:50, :) = reduction1(A, 50, 33, 650, 100);
dataTest(51:100, :) = reduction1(B, 50, 33, 650, 100);
valuesTest(1:50, :) = 1;


% Layer 0 has 2 (+1 threshold) input
    % This would be our random point in the grid.
% Layer 1 has NUM_IN_LAYER1 inputs (+1 threshold) input
% Layer 2 has NUM_IN_LAYER2 inputs (+1 threshold) input
% Layer 3 has 1 output
    % Our guess should be compared to the actual value.

[w1, w2, w3, meanTrialError, meanTestError, ISError, OOSError] = ...
    backProp3Layer(data, values, dataTest, valuesTest, 5, 5, 1000, .1);

%% Images for this section
% imagesc(mickey3)
% imagesc(mickey3 - mickey)
% plot(1:1000, meanTrialError, 1:1000, meanTestError)
% ylabel('Average Error: (output - expected)^2');
% xlabel('Number of Epochs: 900 random samples each');
% title('Error for 2 hidden layers with 10 units each')
% legend('Average Training Error', 'Average Test Error')