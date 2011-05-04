clear all; % cleans up all variables
close all; % closes all figures
clc; % clean up the command window too

%%%%%%%%%%%%%%%%%%% INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

possibleActs = ['walking   ';
                'running   ';
                %'sitting   ';
                'idling    ';
                %'upstairs  ';
                %'downstairs';
                'biking    ' ...
                ];
possibleActs = cellstr(possibleActs);
possibleUser = ['Alex  ';
                'Daiwei';
                'Doris ';
                'Robert';
                'Wenqi '];
possibleUsers = cellstr(possibleUser);
rootDir = 'SensorRecordings';

user = possibleUsers(1)

confusionM = zeros(length(possibleActs));

% Set verbosity of output (0 to 4)
setEnvironment('Diagnostic','verbosity',1);
% Set file ID to write to (1 = stdout)
setEnvironment('Diagnostic','fid',1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:length(possibleActs)
    for j=1:length(possibleActs)
        if i == j
            continue
        end
        
        act1 = possibleActs(i);
        act2 = possibleActs(j);
        display(strcat(act1, '.', act2));

%[X, Y] = rawTrainingDataOVA(rootDir, user, activity);
[XX, YY] = rawTrainingDataOVOld(rootDir, user, act1, act2);
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


useBias	= true;
rand('state',1)
kernel_	= 'bubble';
width	= 1.0;
maxIts	= 1000; % Maximum number of iterations
monIts	= round(maxIts/10); % When to display information
N		= length(values);
Nt		= length(valuesTest);

% Set up initial hyperparameters - precise settings should not be critical
initAlpha	= (1/N)^2;
% Set beta to zero for classification
initBeta	= 0;

% "Train" a sparse Bayes kernel-based model (relevance vector machine)

%while (size(weights,2)) == 0,
disp('Trying to train...');

[weights, used, bias, marginal, alpha, beta, gamma] = ...
    SB1_RVM(data,values,initAlpha,initBeta,kernel_,width,useBias,maxIts,monIts);

%end
% Compute RVM over test data and calculate error
% 
PHI	= SB1_KernelFunction(dataTest,data(used,:),kernel_,width);
ok = 0;
try
    y_rvm	= PHI*weights + bias;
    ok = 1;
catch err
    disp('Cant train RVM');
    confusionM(i,j) = -1;
end

if ok,
errs	= sum(y_rvm(valuesTest==0)>0) + sum(y_rvm(valuesTest==1)<=0);
errs    = errs/Nt;
SB1_Diagnostic(1,'RVM CLASSIFICATION test error: %.2f%%\n', errs)
confusionM(i,j) = errs;
end
    end
end