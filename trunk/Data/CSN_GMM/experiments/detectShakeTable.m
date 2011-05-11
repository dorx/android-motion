%% Apply learned models to the 9-24-2010 Android shake table recordings


import aggregate.*
import roc.*
import synthetic.*
import sac.*
import random.*
import gmm.*

% ------------------------------------------------------------------------
% Load models and thresholds

% GMM LtSt

disp('Oct. 28, test05. GMM LtSt features (2.5,5), train on B, test on A');
load('experiments/Oct28/test05/gmm_ltst.mat', 'models', 'I', 'cThresholds','cTP_amplitudes', 'cFP_amplitudes', 'cParams');

gmm_sensor_TP = cTP_amplitudes{1};
gmm_sensor_FP = cFP_amplitudes{1};
gmmThresholds = cThresholds{I}';

gmmLtStModel = models{I};
gmm_sensor_roc = ReceiverOperatingCharacteristic(gmm_sensor_TP, gmm_sensor_FP, gmmThresholds);
gmmParams = cParams{I};

clear models I cThresholds cParams


% ------------------------------------------------------------------------
% Load Phone Segments

nAndroid = 50;

secondsInaYear = 31556926;
timeStep = 2.5; % seconds
falsePositivesPerYear = 1;

% limit on cell false positive rate
cFpMax = falsePositivesPerYear * (timeStep / secondsInaYear);

secondsInaDay = 86400;
androidMessagesPerDay = 1440;

% limit on android false positive rate
aFpMax =  androidMessagesPerDay * (timeStep / secondsInaDay);

FaultRateA = 0.1;

fprintf('----------------------------------------------\n')
fprintf('cell FP per year: %d\n', falsePositivesPerYear)
fprintf('cell max FP: %1.9f\n\n', cFpMax);
fprintf('Android FP per day: %d\n', androidMessagesPerDay)
fprintf('Android max FP: %f\n\n', aFpMax);
fprintf('Fault Rates, Android: %f\n\n' , FaultRateA);
fprintf('----------------------------------------------\n')

% ------------------------------------------------------------------------
% feature parameters

stLength = 2.5; % seconds per segment

ltLength =  5;

segmentLength = stLength + ltLength + 1;

sampleRate = 50; % segments will be resampled at this rate. samples per second.

%quakeThreshold = 0.3; % m/s^2

% ------------------------------------------------------------------------

VERBOSE = false;


[ gmmCellTp, gmmCellFp, gmmCellROC, gmmSensorTP, gmmSensorFP] = ...
    optimizeCellTruePositive( nAndroid, gmm_sensor_roc, aFpMax, cFpMax);


if VERBOSE
    fprintf('*** GMM operating point ***\n');
    fprintf('gmm cell P_D: %f\n', gmmCellTp);
    fprintf('gmm cell P_F: %f\n', gmmCellFp);
    fprintf('gmm sensor p1: %f\n', gmmSensorTP);
    fprintf('gmm sensor p0: %f\n', gmmSensorFP);
    fprintf('\n\n')
end


% --- get sensor thresholds ----

[~, gmmThreshold] = gmm_sensor_roc.interpolateTruePositiveRate(gmmSensorFP);


% --- load shake table phone segments ---

load('data/shakeTable_9-24-2010/cAndroidShakeSegments', 'cAndroidShakeSegments')
% resample

nSegments = length(cAndroidShakeSegments);
cSegments = cell(nSegments,1); % processed segments
for i=1:nSegments
   seg = cAndroidShakeSegments{i};
   seg_resample = seg.resample(sampleRate);
   cSegments{i} = seg_resample.interval(0,segmentLength);
end


% --- create features ---

cGmmTestingFeatures = ...
    GmLtStParameterSelection.computeTestingLtStFeatures ...
    ({}, cSegments, ltLength, stLength, ...
    gmmParams.numFrequencyCoefficients, gmmParams.numMoments, ...
    gmmParams.C, gmmParams.mu, gmmParams.sigma, gmmParams.dimensionsRetained);


% --- apply GMM model to features ---

gmmAssignments = -log(gmmLtStModel.evaluateProbability(cGmmTestingFeatures));

gmmPickIndices = find(gmmAssignments > gmmThreshold);
nGmmPicks = length(gmmPickIndices);


fprintf('number of gmm picks: %d\n', nGmmPicks);


% --- perform cell-level hypothesis testing ---

%[~, gmmCellThreshold] = gmmCellROC.interpolateTruePositiveRate(gmmCellFp);

%fprintf('gmm Cell Threshold: %f\n' , gmmCellThreshold);

%[gmmCellDecision, gmmCellLR] = cellHypothesisTest( nGmmPicks, n, gmmSensorTP, gmmSensorFP, gmmCellThreshold);


%%
