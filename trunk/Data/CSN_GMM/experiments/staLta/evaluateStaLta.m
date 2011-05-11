%% Evaluate Haff's STA / LTA algorithm



import check.*
import feature.*
import phone.*
import sac.*
import gmm.*
import synthetic.*
import parallel.*
import roc.*

% ------------ parameters -----------------------------------------------

Fc = 10; % Hz cutoff frequency

stLength = 2.5; % seconds per segment

ltLength =  5;

deadTime = 1; % seconds of "dead time" between short term and long term buffers

segmentLength = ltLength + stLength + deadTime;

sampleRate = 50; % segments will be resampled at this rate. samples per second.

threshold = 0.3; % m/s^2


rootDir = '/home/mfaulkne/projects/csn/android_activities/Picking/';

% root directory of SAC e,n,z data channels.
sacRootDir = 'data/sac/5-5.5__0-40km__HN';

% ------------------------------------------------------------------------

% create testing segments and labels



% -------------------------------------------------------------
% combine relatives path with root path.

sacRootDir = [rootDir sacRootDir];
assertDirectory(sacRootDir);

% -------------------------------------------------------------

disp('Loading cached segments')


% Oct24: 2.5s short-term, 5s long-term, 1 "dead" 16-bit
% Phidget data.
% load('*cache/Oct24/phidgetTrainingSegments_ltst.mat');
% cTrainingSegments = cPhidgetTrainingSegments;
% clear cPhidgetTrainingSegments;
% 
% load('*cache/Oct24/phidgetTestingSegments_ltst.mat');
% cTestingNormalSegments = cPhidgetTestingSegments;
% clear cPhidgetTestingSegments;

load('*cache/Oct25/phidgetTrainingSegments_ltst.mat');
cTrainingSegments = cPhidgetTrainingSegments;
clear cPhidgetTrainingSegments;

load('*cache/Oct25/phidgetTestingSegments_ltst.mat');
cTestingNormalSegments = cPhidgetTestingSegments;
clear cPhidgetTestingSegments;


% clear variables that are no longer used:
clear cTestingPhoneRecords

% -------------------------------------------------------------
% Subsample the phone segments.
% If the data
% set of segments is too large, Matlab will be unable to
% serialize (not enough memory?) and will not be able to use
% parfor.

maxTrainingSegments = 10000;
maxTestingSegments = 10000;

numTotalTrainingSegments = length(cTrainingSegments);
numTotalTestingSegments = length(cTestingNormalSegments);

trainingIndicesSubset = random.randomSubset(numTotalTrainingSegments, maxTrainingSegments);
testingIndicesSubset = random.randomSubset(numTotalTestingSegments, maxTestingSegments);

cTrainingSegments = cTrainingSegments(trainingIndicesSubset);
cTestingNormalSegments = cTrainingSegments; % test on A

clear cTrainingSegments;

% -------------------------------------------------------------


% clear variables that are no longer used:
clear cTrainingPhoneRecords
clear cTestingPhoneRecords

cSacRecords = SacLoader.loadSacRecords(sacRootDir);

%
% Create the correct onset segments
%
%
cSyntheticSegments= ...
    SegmentSynthesizer.createOnsetSegments(cTestingNormalSegments, cSacRecords, ...
    ltLength+deadTime, stLength, threshold, 1, sampleRate); % the 1 is "peakAmplitude", now unused.




% ------------------------------------------------------------------------

% create StaLtaFeatures

nTestingNormalSegments = length(cTestingNormalSegments);
cTestingNormalFeatures = cell(nTestingNormalSegments,1);

for i=1:nTestingNormalSegments
    segment = cTestingNormalSegments{i};
    feature = StaLtaFeature(segment, ltLength, stLength, Fc, 2); % 2 is label of "normal" data
    cTestingNormalFeatures{i} = feature;
end

clear cTestingNormalSegments;

nSyntheticSegments = length(cSyntheticSegments);
cSyntheticFeatures = cell(nSyntheticSegments,1);

for i=1:nSyntheticSegments
   segment = cSyntheticSegments{i};
   feature = StaLtaFeature(segment, ltLength, stLength, Fc, 1); % 1 is label of "event" data
   cSyntheticFeatures{i} = feature;
end

clear cSyntheticSegments;

% ------------------------------------------------------------------------

% sweep thresholds

features = [cTestingNormalFeatures; cSyntheticFeatures];
TrueLabels = [2*ones(nTestingNormalSegments,1); 1*ones(nSyntheticSegments,1)];

nFeatures = length(features);
Assignments = zeros(nFeatures,1);
for i=1:nFeatures
    feature = features{i};
    
    Assignments(i) = 1/feature.ratio;
end


% a low hack to deal with the infinite!
infIndices = (Assignments == inf);
Assignments(infIndices) = 1000;
nThresh = 1000;

Thresholds = linspace(min(Assignments), max(Assignments), nThresh);

[tp, fp] =  myROC( TrueLabels, Assignments, Thresholds );
areaUnderCurve = auc(fp,tp);

staLtaROC = ReceiverOperatingCharacteristic(tp, fp);

disp(['AUC: ' num2str(areaUnderCurve)]);

% ------------------------------------------------------------------------

% produce plots


figure()
plot(fp, tp, '.-')
grid on
title(['ROC of STA/LTA, (' num2str(ltLength) ',' num2str(stLength) ')' ])
xlabel('False Positive Rate') % false alarm rate
ylabel('True Positive Rate') % detection rate

% ------------------------------------------------------------------------

% save data
save('StaLta_2.5,5.mat')

