% This script requires onlineSVM to be working.
% The goal is to: 
% 1. Learn the weight vector using the training data Xtrain and Ytrain.
% 2. Classify the test cases in Xtest.
% 3. Plot the test classification error against number of examples.

lambda = 0.1;
possibleActs = ['walking   ';
                'running   ';
                'sitting   ';
                'idling    ';
                'upstairs  ';
                'downstairs';
                'biking    '];
possibleActs = cellstr(possibleActs);
possibleUser = ['Alex  ';
                'Daiwei';
                'Doris ';
                'Robert';
                'Wenqi '];
possibleUsers = cellstr(possibleUser);
rootDir = 'C:\Users\Rumpelteazer\Documents\Caltech\AndroidMotion\Data\SensorRecordings\';

user = possibleUsers(1)
activity = possibleActs(1)
act1 = possibleActs(1)
act2 = possibleActs(2)
% Get training and testing data
% %[X, Y] = rawTrainingDataOVA(rootDir, user, activity);
[XX, YY] = rawTrainingDataOVO(rootDir, user, act1, act2);
% %redX = reduction(X);
redXX = reduction2(XX);
redXX = horzcat(redXX, ones(size(redXX, 1),1));
redXX = redXX./repmat(sqrt(sum(redXX.^2,2)),1,size(redXX,2));

% % OVA
% N = size(redX,1);
% [Xtrain, Ytrain, Xtest, Ytest] = separate(redX, Y, 0.3);
% numbers = int32((0.1:0.1:1)*N);
% t = zeros(1, size(numbers, 2));
% acc = zeros(1, size(numbers, 2));
% Wall = zeros(size(numbers, 2), size(Xtrain, 2));
% yall = zeros(size(Xtest, 1), size(numbers, 2));
% 
% for i=1:length(numbers)
%     numbers(i)
%     % subsample the data
%     [XtrainSample, YtrainSample] = subsample(Xtrain, Ytrain, numbers(i));
%     
%     % obtain margin for test cases
%     tic
%     W2 = onlineSVM(XtrainSample, YtrainSample, lambda);
%     Wall(i, :) = W2;
%     % classify test examples
%     y2 = dot(Xtest, repmat(W2, size(Xtest, 1), 1), 2);
%     yy2= sign(y2);
%     sum(Ytest==1)
%     yall(:, i) = yy2;
%     % obtain run-time and accuracy for test examples
%     t(i) = toc;
%     acc(i) = double(sum(yy2==Ytest))/length(Ytest);
%     double(sum(yy2==Ytest))/length(Ytest)
% end
% save('OVAresults.mat', 'Wall', 'acc', 't', 'numbers', 'yall')

% OVO
NN = size(redXX,1);
[XXtrain, YYtrain, XXtest, YYtest] = separate(redXX, YY, 0.3);
Numbers = int32((0.1:0.1:1)*size(XXtrain, 1));
tt = zeros(1, size(Numbers, 2));
aacc = zeros(1, size(Numbers, 2));
WWall = zeros(size(Numbers, 2), size(XXtrain, 2));
yyall = zeros(size(XXtest, 1), size(Numbers, 2));

for j=1:length(Numbers)
    % subsample the data
    [XXtrainSample, YYtrainSample] = subsample(XXtrain, YYtrain, Numbers(j));
    
    % obtain margin for test cases
    tic
    WW2 = onlineSVM(XXtrainSample, YYtrainSample, lambda);
    WWall(j, :) = WW2;
    % classify test examples
    y2a = dot(XXtest, repmat(WW2, size(XXtest, 1), 1), 2);
    yy2a= sign(y2a);
    yyall(:, j) = yy2a;
    % obtain run-time and accuracy for test examples
    tt(j) = toc;
    aacc(j) = double(sum(yy2a==YYtest))/length(YYtest);
end
save('OVOresults.mat', 'WWall', 'aacc', 'tt', 'Numbers', 'yyall')

