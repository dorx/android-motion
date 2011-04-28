clear all; % cleans up all variables
close all; % closes all figures
clc; % clean up the command window too


%%%%%%%%%%%%%%%%%%% INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

A = load('SensorRecordings\Alex_running_04051515.acsn');
B = load('SensorRecordings\Alex_walking_04051545.acsn');

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set verbosity of output (0 to 4)
setEnvironment('Diagnostic','verbosity',3);
% Set file ID to write to (1 = stdout)
setEnvironment('Diagnostic','fid',1);

useBias	= true;
rand('state',1)
N		= 100;
kernel_	= 'gauss';
width		= 0.5;
maxIts	= 1000; % Maximum number of iterations
monIts		= round(maxIts/10); % When to display information
N		= min([250 N]); % training set has fixed size of 250
Nt		= 1000;


% Set up initial hyperparameters - precise settings should not be critical
initAlpha	= (1/N)^2;
% Set beta to zero for classification
initBeta	= 0;	


% "Train" a sparse Bayes kernel-based model (relevance vector machine)
% 
[weights, used, bias, marginal, alpha, beta, gamma] = ...
    SB1_RVM(data,values,initAlpha,initBeta,kernel_,width,useBias,maxIts,monIts);

% Compute RVM over test data and calculate error
% 
PHI	= SB1_KernelFunction(dataTest,data(used,:),kernel_,width);
y_rvm	= PHI*weights + bias;
errs	= sum(y_rvm(valuesTest==0)>0) + sum(y_rvm(valuesTest==1)<=0);
SB1_Diagnostic(1,'RVM CLASSIFICATION test error: %.2f%%\n', errs/Nt*100)