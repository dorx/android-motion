
import gmm.*

% data

%data.rootDir = '/home/mfaulkne/projects/csn/android_activities/Picking/';
data.rootDir = '/home/mfaulk/projects/csn/android_activities/Picking/';

% directory of phone training data
data.phoneTrainingDir = 'data/droid/csnAndroidLogs/A';
%
%data.phoneTrainingDir = 'test/testData/acsnDir'; % for debugging

% directory of phone testing data
data.phoneTestingDir = 'data/droid/csnAndroidLogs/B';
%
%data.phoneTestingDir = 'test/testData/acsnDir'; % for debugging

% root directory of training SAC e,n,z data channels.
data.sacTrainingRootDir = 'data/sac/4.5-5__HN';

% root directory of testing SAC e,n,z data channels.
data.sacTestingRootDir = 'data/sac/5-5.5__0-40km__HN';

% ------------------------------------------------------------------------

% GMM parameters

parameters.NumGaussians = [5];

% XyzFeature parameter ranges

parameters.NumFrequencyCoefficients = [16,32];

parameters.NumMoments = [1];%[1,2,3,4];

% PcaFeature parameters

performPCA = true; % this may not do anything at the moment.

parameters.DimensionsRetained = [1,2];
% other parameters

parameters.stLength = 2.5; % seconds per segment

parameters.ltLength =  5;

parameters.sampleRate = 50; % segments will be resampled at this rate. samples per second.

parameters.threshold = 0.3; % m/s^2

% parameters.scale = 100;

% ------------------------------------------------------------------------

peakAmplitudes = [1]; % m/s^2

cTP_amplitudes= cell(length(peakAmplitudes),1);
cFP_amplitudes = cell(length(peakAmplitudes),1);


for i=1:length(peakAmplitudes)
   parameters.peakAmplitude = peakAmplitudes(i);
   disp(['Peak Amplitude: ' num2str(parameters.peakAmplitude)]);
   
   [AUC cTP cFP cParams models cThresholds] = HypothesisTestParameterSelection.evaluateParameters(data, parameters);
   [maxAUC, I] = max(AUC);
   disp(['Maximum AUC: ' num2str(maxAUC)])
   
   bestParams = cParams{I};
   disp(bestParams)
   
   TP = cTP{I};
   FP = cFP{I};
   
   % save the values from the best parameters
   cTP_amplitudes{i} = TP;
   cFP_amplitudes{i} = FP;
end


% convert cTP_scales to matrix
mTP = cell2mat(cTP_amplitudes');
mFP = cell2mat(cFP_amplitudes');

figure()
plot(mFP, mTP, '.-')
grid on
title(['ROC of H.T., ' data.phoneTrainingDir ', ' data.phoneTestingDir])
xlabel('False Positive Rate')
ylabel('True Positive Rate')


% automatically assign legend values
% legendStrings = cell(length(peakAmplitudes),1);
% for i=1:length(peakAmplitudes)
%    legendStrings{i} = [num2str(peakAmplitudes(i)) ' m/s^2' ]; 
% end
% 
% legend(legendStrings, 'Location', 'SouthEast')

%


save('ht_ltst')

saveFigs = false;
if saveFigs
   saveas(gcf, 'ht_ltst_roc', 'fig'); 
   saveas(gcf, 'ht_ltst_roc', 'png'); 
end

matlabpool close

disp('Done');




