clear all; % cleans up all variables
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
rootDir = 'SensorRecordings';

user = possibleUsers(1)
%activity = possibleActs(1)



confusionM = zeros(length(possibleActs));

for i=1:1%length(possibleActs)
    for j=3:3%length(possibleActs)
        if i == j
            continue
        end
        
        act1 = possibleActs(i);
        act2 = possibleActs(j);
        display(strcat(act1, '.', act2));

%[X, Y] = rawTrainingDataOVA(rootDir, user, activity);
[XX, YY] = rawTrainingDataOVO_unix(rootDir, user, act1, act2);
%redX = reduction(X);
redXX = reduction3(XX);


num1 = sum(YY);
num0 = sum(1 - YY);

num = min(num0, num1);
% ones appear first when running rawTrainingData
data = [redXX(1:int32(num / 2), :); redXX((num1+1):(num1+int32(num/2)), :)];
values = [YY(1:int32(num / 2), :); YY((num1+1):(num1+int32(num/2)), :)];
dataTest = [redXX(int32(num/2):num, :); redXX((num1+int32(num/2)+1):(num1+num), :)];
valuesTest = [YY(int32(num/2):num, :); YY((num1+int32(num/2)+1):(num1+num), :)];



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

[InError, OutError, centers] = kcluster(data, values, dataTest, valuesTest);

%cc = sum(abs(classify3LayerStrict(dataTest', w1, w2, w3)' -  valuesTest))

        %confusionM(i, j) = cc / length(dataTest);

        confusionM(i, j) = OutError;
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