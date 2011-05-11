%%

import gmm.*

% data

%data.rootDir = '/home/mfaulkne/projects/csn/android_activities/Picking/';
data.rootDir = '/home/mfaulk/projects/csn/android_activities/Picking/';

% directory of phone training data
%data.phoneTrainingDir = 'data/droid/csnAndroidLogs/A';
data.phoneTrainingDir = 'data/droid/trainMixed';

% directory of phone testing data
%data.phoneTestingDir = 'data/droid/csnAndroidLogs/B';
data.phoneTestingDir = 'data/droid/punch';
data.phoneTestingDir = 'data/droid/testMixed';

% root directory of SAC e,n,z data channels.
data.sacRootDir = 'data/sac/5-5.5__0-40km__HN';

% ------------------------------------------------------------------------

% GMM parameters

parameters.NumGaussians = [3];

% XyzFeature parameter ranges

parameters.NumFrequencyCoefficients = [16];

parameters.NumMoments = [4];%[1,2,3,4];

% PcaFeature parameters

performPCA = true;

parameters.DimensionsRetained = [6,8,10];
% other parameters

parameters.segmentLength = 2.5; % seconds per segment

parameters.sampleRate = 50; % segments will be resampled at this rate. samples per second.

parameters.threshold = 0.3; % m/s^2

% parameters.scale = 100;

% ------------------------------------------------------------------------

scales = [1];

cTP_scales = cell(length(scales),1);
cFP_scales = cell(length(scales),1);

for i=1:length(scales)
   %parameters.scale = scales(i);
   %disp(['Scale: ' num2str(parameters.scale)]);
   parameters.peakAmplitude = 1; % not used...
   [AUC cTP cFP cParams models] = GmParameterSelection.evaluateParameters(data, parameters);
   [maxAUC, I] = max(AUC);
   disp(['Maximum AUC: ' num2str(maxAUC)])
   
   bestParams = cParams{I};
   disp(bestParams)
   
   TP = cTP{I};
   FP = cFP{I};
   
   % save the values from the best parameters
   cTP_scales{i} = TP;
   cFP_scales{i} = FP;
end


% convert cTP_scales to matrix
mTP = cell2mat(cTP_scales');
mFP = cell2mat(cFP_scales');

figure()
plot(mFP, mTP, '.-')
grid on
title(['ROC of GMM, ' data.phoneTrainingDir ', ' data.phoneTestingDir ', vs quake scale'])
xlabel('False Positive Rate') % false alarm rate
ylabel('True Positive Rate') % detection rate


% automatically assign legend values
legendStrings = cell(length(scales),1);
for i=1:length(scales)
   legendStrings{i} = num2str(scales(i)); 
end

legend(legendStrings, 'Location', 'SouthEast')

%

save('gm_xyz_switched')

matlabpool close;

disp('Done');




