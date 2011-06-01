%clear all; % cleans up all variables
close all; % closes all figures
clc; % clean up the command window too


possibleActs = ['walking   ';
                'running   ';
                %'sitting   ';
                'idling    ';
                %'upstairs  ';
                %'downstairs';
                'biking    '];
possibleActs = cellstr(possibleActs);
possibleUser = ['Alex  ';
                'Daiwei';
                'Doris ';
                'Robert';
                'Wenqi '];
possibleUsers = cellstr(possibleUser);
%rootDir = 'C:\Users\AlexFandrianto\Documents\MATLAB\CS141\BackProp\Data';%'C:\Users\Rumpelteazer\Documents\Caltech\AndroidMotion\Data\SensorRecordings\';

user = possibleUsers(1)
%activity = possibleActs(1)

%load('C:\Users\AlexFandrianto\Documents\MATLAB\CS141\BackProp\ReducedData\data_Alex_red3_learnable.mat')

confusionM = zeros(length(possibleActs));

for i=1:length(possibleActs)
    for j=1:length(possibleActs)
        if i == j %|| (i == 4 || i == 5 || j == 4 || j == 5)
            continue
        end
        
        act1 = possibleActs(i);
        act2 = possibleActs(j);
        display(strcat(act1, '.', act2));

%[X, Y] = rawTrainingDataOVA(rootDir, user, activity);
%[XX, YY] = rawTrainingDataOVO(rootDir, user, act1, act2);
%redX = reduction(X);
%redXX = reduction3(XX);

% ones appear first when running rawTrainingData
data = [TRAIN{i} ; TRAIN{j}];
values = [ones(length(TRAIN{i}(:, 1)), 1) ; 0 * ones(length(TRAIN{j}(:, 1)), 1)];
dataTest = [TEST{i} ; TEST{j}];
valuesTest = [ones(length(TEST{i}(:, 1)), 1) ; 0 * ones(length(TEST{j}(:, 1)), 1)];



% data = zeros(40, 3);
% values = zeros(40, 1);
% 
% data(1:20, :) = reduction1(A, 20, 3, 650, 100);
% data(21:40, :) = reduction1(B, 20, 3, 650, 100);
% values(1:20, :) = 1;
% 
% dataTest = zeros(100, 3);
% valuesTest = zeros(100, 1);
% 
% dataTest(1:50, :) = reduction1(A, 50, 33, 650, 100);
% dataTest(51:100, :) = reduction1(B, 50, 33, 650, 100);
% valuesTest(1:50, :) = 1;
% 
% 
% Layer 0 has 2 (+1 threshold) input
    % This would be our random point in the grid.
% Layer 1 has NUM_IN_LAYER1 inputs (+1 threshold) input
% Layer 2 has NUM_IN_LAYER2 inputs (+1 threshold) input
% Layer 3 has 1 output
    % Our guess should be compared to the actual value.

[w1, w2, w3, meanTrialError, meanTestError, ISError, OOSError, weights1, weights2, weights3] = ...
    backProp3Layer(data, values, dataTest, valuesTest, 5, 5, 500, .1);

cc = sum(abs(classify3LayerStrict(dataTest', w1, w2, w3)' -  valuesTest))

        confusionM(i, j) = cc / length(dataTest);

    end
end

%% Images for this section
% imagesc(mickey3)
% imagesc(mickey3 - mickey)
% plot(1:1000, meanTrialError, 1:1000, meanTestError)
% ylabel('Average Error: (output - expected)^2');
% xlabel('Number of Epochs: 900 random samples each');
% title('Error for 2 hidden layers with 10 units each')
% legend('Average Training Error', 'Average Test Error')