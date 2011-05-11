function test_suite = testAggregate
clear all; % to reload class definitions
initTestSuite;
% xUnit test suite. Functions must not end with "end" statement.
%
% author: Matt Faulkner

% ------------------------------------------------------------------------

function testComputeCellRocTwoTypes()
import  aggregate.*

tpA = 0.6;
fpA = 0.1;

tpB = 0.6;
fpB = 0.1;

% performance should be symmetric:

firstTPR = max(computeCellRocTwoTypes(5,0, tpA, fpA, tpB, fpB));
secondTPR = max(computeCellRocTwoTypes(0,5, tpA, fpA, tpB, fpB));

assertEqual(firstTPR, secondTPR);

% ------------------------------------------------------------------------

function testOptimizeCellTwoTypes()
import aggregate.*
import roc.*

% make some ROC curves
% sensor ROC curve:
tpr = [0; 0.3; 0.5; 0.6; 0.7; 0.8; 0.9; 1];
fpr = [0; 0.1; 0.2; 0.3; 0.4; 0.5; 0.7; 1];
sensorRocA = ReceiverOperatingCharacteristic(tpr, fpr);

% sensor ROC curve:
tpr = [0; 0.3; 0.5; 0.6; 0.7; 0.8; 0.9; 1];
fpr = [0; 0.1; 0.2; 0.3; 0.4; 0.5; 0.7; 1];
sensorRocB = ReceiverOperatingCharacteristic(tpr, fpr);

sRoc = cell(2,1);
sRoc{1} = sensorRocA;
sRoc{2} = sensorRocB;

nA = 10;
nB = 2;

N = [nA; nB];


maxSfpA = 0.2;
maxSfpB = 0.2;

maxSfp = [maxSfpA; maxSfpB];

maxCellFalsePositive = 0.05;

[ TPR, FPR, SensorTP, SensorFP ] = ...
    optimizeCellTwoTypes(N, sRoc, maxSfp, maxCellFalsePositive);

 %[ tpr, fpr ] = computeCellRocTwoTypes(nA, nB, tpA, fpA, tpB, fpB)

 %surf(TPR)

% ------------------------------------------------------------------------