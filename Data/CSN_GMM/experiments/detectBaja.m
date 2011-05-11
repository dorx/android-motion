%% Apply the learned models to specific testing data sets
% load the models. 
% load the cached segments that were used to train / test the models
% create features
% apply models

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

% HT LtSt

disp('Oct. 28, test 06. Hypothesis test LtSt features (2.5,5), train on B, test on A')
load('experiments/Oct28/test06/ht_ltst.mat', 'models', 'I', 'cThresholds','cTP_amplitudes', 'cFP_amplitudes', 'cParams');

ht_sensor_TP = cTP_amplitudes{1};
ht_sensor_FP = cFP_amplitudes{1};
htThresholds = cThresholds{I}';
htParams = cParams{I};

ht_sensor_roc = ReceiverOperatingCharacteristic(ht_sensor_TP, ht_sensor_FP, htThresholds);
htLtStModel = models{I};


clear models I cThresholds cParams


% ------------------------------------------------------------------------
% Load Phone Segments


% directory of phone testing data
data.phoneTestingDir = 'data/droid/csnAndroidLogs/B';
%
%data.phoneTestingDir = 'test/testData/acsnDir'; % for debugging

% test 01: 2.5s short-term, 5s long-term, 1 "dead"
                
load('*cache/Oct18/test01/trainingSegments');
%load('*cache/Oct18/test01/testingNormalSegments.mat');

% LOOK: on oct18, I wanted to use one a particular data set for training; I used
% a different data set to train the models used here, so the variable name
% 'cTrainingSegments' is a misnomer. These are not the training data I used
% to train the models in this file.
cPhoneSegments = cTrainingSegments; 

% ------------------------------------------------------------------------
% Load SAC records


% root directory of testing SAC e,n,z data channels.
sacTestingRootDir = 'data/sac/6-8__HN'; % Baja M7.2

% load the sac records
cSacRecords = SacLoader.loadSacRecords(sacTestingRootDir);

% ------------------------------------------------------------------------
% sensor parameters

N_Android = 1:2:100; % range of values for the number of androids

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

quakeThreshold = 0.3; % m/s^2

% ------------------------------------------------------------------------


nSizes = length(N_Android);

nIterations = 100;

gmmLikelihoods = zeros(nSizes,1);

htLikelihoodRatios = zeros(nSizes,1);

% save the operating points

% save the binary decisions
GmmCellTP = zeros(nSizes,nIterations);
HtCellTP = zeros(nSizes,nIterations);

GmmCellDecisions = zeros(nSizes,nIterations);
HtCellDecisions = zeros(nSizes,nIterations);

GmmNumPicks = zeros(nSizes,nIterations);
HtNumPicks = zeros(nSizes,nIterations);

VERBOSE = false;

% if matlabpool('size')==0
%     try
%         matlabpool open
%     catch exception
%         disp('Exception opening matlab pool')
%         disp(exception)
%     end
% end



for i=1:nSizes
    for j = 1:nIterations
    % estimate the best sensor operating point
    n = N_Android(i);
    fprintf('number of phones: %d\n\n', n)
    
    
    [ gmmCellTp, gmmCellFp, gmmCellROC, gmmSensorTP, gmmSensorFP] = ...
        optimizeCellTruePositive( n, gmm_sensor_roc, aFpMax, cFpMax);
    %
    
    [ htCellTp, htCellFp, htCellROC, htSensorTP, htSensorFP] = ...
        optimizeCellTruePositive( n, ht_sensor_roc, aFpMax, cFpMax);
    
    if VERBOSE
        fprintf('*** GMM operating point ***\n');
        fprintf('gmm cell P_D: %f\n', gmmCellTp);
        fprintf('gmm cell P_F: %f\n', gmmCellFp);
        fprintf('gmm sensor p1: %f\n', gmmSensorTP);
        fprintf('gmm sensor p0: %f\n', gmmSensorFP);
        fprintf('\n\n')
        
        
        fprintf('*** HT operating point ***\n');
        fprintf('ht cell P_D: %f\n', htCellTp);
        fprintf('ht cell P_F: %f\n', htCellFp);
        fprintf('ht sensor p1: %f\n', htSensorTP);
        fprintf('ht sensor p0: %f\n', htSensorFP);
        fprintf('\n\n')
        
    end
    
   
   % --- get sensor thresholds ----
   
   [~, gmmThreshold] = gmm_sensor_roc.interpolateTruePositiveRate(gmmSensorFP);
   [~, htThreshold] = ht_sensor_roc.interpolateTruePositiveRate(htSensorFP);
   
   % --- generate synthetic segments (phone + Baja) ---
   
   % randomly choose n phone segments
   A = randomSubset( length(cPhoneSegments), n );
   cTestingSegments = cPhoneSegments(A);
   
   cSyntheticSegments = ...
       SegmentSynthesizer.createSyntheticSegments(cTestingSegments, cSacRecords, ...
       segmentLength, sampleRate, quakeThreshold, 1); % 1 is dummy value
   
   % --- create features ---
   
   cGmmTestingFeatures = ...
       GmLtStParameterSelection.computeTestingLtStFeatures ...
       ({}, cSyntheticSegments, ltLength, stLength, ...
       gmmParams.numFrequencyCoefficients, gmmParams.numMoments, ...
       gmmParams.C, gmmParams.mu, gmmParams.sigma, gmmParams.dimensionsRetained);
   
   cHtTestingFeatures = ...
       GmLtStParameterSelection.computeTestingLtStFeatures ...
       ({}, cSyntheticSegments, ltLength, stLength, ...
       htParams.numFrequencyCoefficients, htParams.numMoments, ...
       htParams.C, htParams.mu, htParams.sigma, htParams.dimensionsRetained);
   
   % --- apply GMM model to features ---
   
   gmmAssignments = -log(gmmLtStModel.evaluateProbability(cGmmTestingFeatures));
   
   gmmPickIndices = find(gmmAssignments > gmmThreshold);
   nGmmPicks = length(gmmPickIndices);
   
   
   % --- apply HT model to features ---
   
   htNumModel = htLtStModel{1};
   htDenomModel = htLtStModel{2};
   
   htAssignments = -log(htNumModel.evaluateProbability(cHtTestingFeatures)) + log(htDenomModel.evaluateProbability(cHtTestingFeatures));
   
   htPickIndices = find(htAssignments > htThreshold);
   nHtPicks = length(htPickIndices);
   
   
   if VERBOSE
       fprintf('number of gmm picks: %d\n', nGmmPicks);
       fprintf('number of ht picks: %d\n', nHtPicks);
   end
   
   
   % --- perform cell-level hypothesis testing ---
   
   [~, gmmCellThreshold] = gmmCellROC.interpolateTruePositiveRate(gmmCellFp);
   [~, htCellThreshold] = htCellROC.interpolateTruePositiveRate(htCellFp);
   
   %fprintf('gmm Cell Threshold: %f\n' , gmmCellThreshold);
   %fprintf('ht Cell Threshold: %f\n' , htCellThreshold);
   
   [gmmCellDecision, gmmCellLR] = cellHypothesisTest( nGmmPicks, n, gmmSensorTP, gmmSensorFP, gmmCellThreshold);
   
   [htCellDecision, htCellLR] = cellHypothesisTest( nHtPicks, n, htSensorTP, htSensorFP, htCellThreshold);
   
   if VERBOSE
       if gmmCellDecision == 1
           disp('GMM detected event')
       end
       
       if htCellDecision == 1
           disp('HT detected event')
       end
   end
   
   % --- save values ---
   
   GmmCellTP(i,j) = gmmCellTp;
   HtCellTP(i,j) = htCellTp;
   
   GmmCellDecisions(i,j) = gmmCellDecision;
   HtCellDecisions(i,j) = htCellDecision;
   
   GmmNumPicks(i,j) = nGmmPicks;
   HtNumPicks(i,j) = nHtPicks;
   
   disp('-------------------------------------------------')
    end
end


%%

load('experiments/Oct28/test07/baja.mat')

% take the mean of each row:
gmmMeanDecisions = mean(GmmCellDecisions, 2);
htMeanDecisions = mean(HtCellDecisions,2);

FONT_SIZE = 16;

figure()
p = plot(N_Android, gmmMeanDecisions, 'r', N_Android, GmmCellTP(:,1), 'r.', N_Android, htMeanDecisions, 'b');
xlabel('Number of Phones', 'FontSize', FONT_SIZE)
ylabel('Empirical Detection Rate', 'FontSize', FONT_SIZE)
%legend('GMM LtSt', 'GMM estimate', 'HT LtSt','Location','SouthEast' )
title('Baja M7.2')
h = get(gca, 'title');
set(h, 'FontSize', FONT_SIZE)
set(p,'LineWidth',2)
set(gca, 'FontSize', FONT_SIZE)

% error bars
% compute std dev of each row
figure()
gmmE = std(GmmCellDecisions,1,2);
errorbar(N_Android, gmmMeanDecisions, gmmE)

%% Apply the models to the shake table data
% load the models and the shake table android data.
% For both GMM and HT,
% apply the operating points used for the two sensor scenarios we've
% considered: 1 pick per minute, and 2 picks per hour
%
% find the corresponding threshold for these operating points
% make features from the android shake table data.
% 
% Would each alg+threshold have picked for these data?






