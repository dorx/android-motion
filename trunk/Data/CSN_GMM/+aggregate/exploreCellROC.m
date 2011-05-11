%% scratch space

import aggregate.*
import roc.*
import auc.*

% true positive rate for each sensor 
truePositiveSensor = 0.5;
falsePositiveSensor = 0.1;

% number of sensors in cell:
N = 50;

cellROC = computeCellROC(N, truePositiveSensor, falsePositiveSensor);
TPR = cellROC.truePositiveRates;
FPR = cellROC.falsePositiveRates;

%plot(cellROC)

figure()
plot(FPR, TPR)
axis([0,1,0,1])

%% evaluate the effect of N on the ROC curves, for fixed sensor tp, fp
import aggregate.*
import roc.*
import auc.*

% true positive rate for each sensor 
truePositiveSensor = 0.4;
falsePositiveSensor = 0.25;

% number of sensors in cell:
N = [1, 5, 10, 25];

% cell arrays of tp and fp vectors
cTPR = cell(length(N),1);
cFPR = cell(length(N),1);

for i=1:length(N)
    n = N(i);
    cellROC = computeCellROC(n, truePositiveSensor, falsePositiveSensor);
    tpr = cellROC.truePositiveRates;
    fpr = cellROC.falsePositiveRates;
    cTPR{i} = tpr;
    cFPR{i} = fpr;
end

% plot all

% convert cTP_scales to matrix. For this to work, all the contents of each
% cell need to be the same length, so that they can be shuffled into a
% matrix. To accomplish this, pad with leading 0's
%

maxLength = max(cellfun(@length, cTPR));

for i=1:length(N)
    tpr = cTPR{i};
    fpr = cFPR{i};
    numberOfAdditionalZeros = maxLength - length(tpr);
    padding = zeros(numberOfAdditionalZeros, 1);
    tpr = [padding; tpr];
    fpr = [padding; fpr];
    cTPR{i} = tpr;
    cFPR{i} = fpr;
end

mTP = cell2mat(cTPR');
mFP = cell2mat(cFPR');

figure()
plot(mFP, mTP, '.-')
title(['Cell-level ROC. sensor TP: ' num2str(truePositiveSensor) ' FP: ' num2str(falsePositiveSensor) ])
xlabel('False Positive Rate')
ylabel('True Positive Rate')


% automatically assign legend values
legendStrings = cell(length(N),1);
for i=1:length(N)
   legendStrings{i} = num2str(N(i)); 
end

legend(legendStrings, 'Location', 'SouthEast')



%% Optimize the cell tpr, given cell fpr constraint
clear all; close all

import aggregate.*
import roc.*

% sensor ROC curve:
tpr = [0; 0.3; 0.5; 0.6; 0.7; 0.8; 0.9; 1];
fpr = [0; 0.1; 0.2; 0.3; 0.4; 0.5; 0.7; 1];
sensorROC = ReceiverOperatingCharacteristic(tpr, fpr);

figure()
plot(sensorROC.falsePositiveRates, sensorROC.truePositiveRates)
xlabel('False Positive Rate')
ylabel('True Positive Rate')
title('Sensor ROC curve')

% constraint on sensor false positive rate
maxSensorFalsePositive = 0.6;

% constraint on cell false positive rate
maxCellFalsePositive = 0.1;

% number of sensors in the cell
nSensors = 10;

 [ tp, fp, cellROC, sensorTP, sensorFP] = ...
    optimizeCellTruePositive( nSensors, sensorROC, maxSensorFalsePositive, maxCellFalsePositive );

disp(['Cell True Positive Rate: ' num2str(tp)])
disp(['Cell False Positive Rate: ' num2str(fp)])

disp(['Sensor tp: ' num2str(sensorTP)])
disp(['Sensor fp: ' num2str(sensorFP)])

figure
plot(cellROC.falsePositiveRates, cellROC.truePositiveRates)
xlabel('False Positive Rate')
ylabel('True Positive Rate')
title(['Cell-level ROC. Max Sensor FP: ' num2str(maxSensorFalsePositive) ' max Cell FP: ' num2str(maxCellFalsePositive)])

% might want to plot sensor ROC and cell ROC on same axes. Then, I could
% mark the sensor true positive, false positive operating point on the
% curve. Might also draaw in the constraints on the false positive rates.



%% V(N) - plot the effect of the number of sensors on the obtainable cell
% true positive rate

clear all; close all

import aggregate.*
import roc.*

% sensor ROC curve:
% tpr = [0; 0.5; 0.7; 0.85; 0.87; 0.95; 0.99; 1];
% fpr = [0; 0.01; 0.05; 0.3; 0.4; 0.5; 0.7; 1];
% sensorROC = ReceiverOperatingCharacteristic(tpr, fpr);


disp('Oct. 19, test04. GMM LtSt features (2.5,5), train on B, test on A');
load('experiments/Oct19/test04/gmm_ltst_switched.mat');
% get the ROC curve, best parameters, rename, clear the rest
oct19test04_tp = cTP_amplitudes{1};
oct19test04_fp = cFP_amplitudes{1};
sensorROC = ReceiverOperatingCharacteristic(oct19test04_tp, oct19test04_fp);

figure()
plot(sensorROC.falsePositiveRates, sensorROC.truePositiveRates)
grid on
xlabel('False Positive Rate')
ylabel('True Positive Rate')
title('Sensor ROC curve')

secondsInaYear = 31556926;
timeStep = 2.5; % seconds
falsePositivesPerYear = 0.005;

% limit on cell false positive rate
cFpMax = falsePositivesPerYear * (timeStep / secondsInaYear); 

secondsInaDay = 86400;
sensorMessagesPerDay = 360;

% limit on android false positive rate
sFpMax =  sensorMessagesPerDay * (timeStep / secondsInaDay); 

FaultRates = [0.1, 0.1];

% number of sensors in the cell
nSensors = 1:5:100;

fprintf('----------------------------------------------\n')
fprintf('cell FP per year: %d\n', falsePositivesPerYear)
fprintf('cell max FP: %1f15\n\n', cFpMax);

fprintf('Sensor FP per day: %d\n', sensorMessagesPerDay)
fprintf('Sensor max FP: %1f15\n\n', sFpMax);

fprintf('Fault Rates, Android: %f,  Phidget: %f\n\n' ,FaultRates(1), FaultRates(2));
fprintf('----------------------------------------------\n')



[ cellTP, cellFP, sensorTP, sensorFP, cCellROC ] = ...
    cellPerformanceVsDensity( sensorROC, sFpMax, cFpMax, nSensors);

figure()
plot(nSensors, cellTP)
grid on
xlabel('Number of Sensors in Cell')
ylabel('Cell True Positive Rate')
title(['Cell performance vs. sensor density. Max Sensor FP: ' num2str(sFpMax) ' max Cell FP: ' num2str(cFpMax)])

% figure()
% ax = plotyy(nSensors, sensorTP, nSensors, sensorFP);
% grid on
% xlabel('Number of Sensors in Cell')
% title(['Sensor operating point vs sensor density . Max Sensor FP: ' num2str(maxSensorFalsePositive)]) 
% legend('sensorTP', 'sensorFP')
% axes(ax(1));
% axis([1 100 0 1])
% axes(ax(2)); 
% axis([1 100 0 1])

% Plot a few of the cell ROC curves?

%% Produce plots of V(n) for several communication constraints
% For IPSN

clear all; 
%close all

import aggregate.*
import roc.*

disp('Oct. 19, test04. GMM LtSt features (2.5,5), train on B, test on A');
load('experiments/Oct19/test04/gmm_ltst_switched.mat');
% get the ROC curve, best parameters, rename, clear the rest
oct19test04_tp = cTP_amplitudes{1};
oct19test04_fp = cFP_amplitudes{1};
sensorROC = ReceiverOperatingCharacteristic(oct19test04_tp, oct19test04_fp);

% figure()
% plot(sensorROC.falsePositiveRates, sensorROC.truePositiveRates)
% grid on
% xlabel('False Positive Rate')
% ylabel('True Positive Rate')
% title('Sensor ROC curve')

% -----------------------------------------------------------------------

% vector of number of sensors
nSensors = 1:100;

faultRate = 0.1;

secondsInaYear = 31556926;
timeStep = 2.5; % seconds
falsePositivesPerYear = [1, 0.1, 0.001, 0.005];

% limit on cell false positive rate
cFpMaxVals = falsePositivesPerYear * (timeStep / secondsInaYear); 

sFpMax = 0.04166715;

nIterations = length(cFpMaxVals);

cCellTp = cell(nIterations,1);
for i=1:nIterations
    cFpMax = cFpMaxVals(i);
    
    cellTp = cellPerformanceVsDensity( sensorROC, sFpMax, cFpMax, nSensors, faultRate);
    cCellTp{i} = cellTp; % yes, a cell array of "cell-level ROC curves"
end



figure()
plot(nSensors, cCellTp{1}, nSensors, cCellTp{2}, nSensors, cCellTp{3}, nSensors, cCellTp{4})
grid on
xlabel('Number of Phones')
ylabel('Detection Rate')

