%% Make plots for the 2011 IPSN paper
%
% author: Matt Faulkner
%

% summary of experimental results:
%
% TODO: move gmmPlots/Oct17 to be with the rest
%
% Oct. 18 (I didn't save the PCA parameters, so later I re-ran these
% experiments. I think all these tests were done again on Oct. 28
%
%   test01 - GMM LtSt features (2.5s, 5s) train A test B
%
%   test02 - GMM with LtSt features: 2.5 second short
%     term, 25 second long term. Train A, Test B
%
%   test03 - Hypothesis testing with LtSt features. Train on A, test on B.  
%     used ``sac/4.5-5'' to produce the synthetic training examples.
%
% Oct. 19
% 
%   test01
%   test02
%   test03 - GMM, XYZ features, train on B, test on A
%
%   test04 - GMM LtSt features (2.5,5), train on B, test on A
%
%   test05 - hypothesis testing with Long-term Short
%     term features (2.5s,25s). Train on B, test on A. Same training and
%     testing quakes.
%
%
%   test06 -  GMM LtSt 2.5s, 25s. Train B, test A. 
%
%   test07  - Hypothesis testing, LtSt features 2.5s,
%       5s. Same Training and testing quakes.
%
%   test08 - Hypothesis testing. LtSt 2.5s,5s. Trained
%       on magnitude 6-8 quakes, tested on magnitude 5-5.5 quakes.
%     
% 
% Oct 20
%
%   test01 - STA/LTA, 2.5s short term, 5s long term.
%   test02 - STA/LTA, 2.5s short term, 25s long term
%
% Oct 21
%
%   test01 - HT, trained with one quake example per SAC file.
%       Trained on \verb=5-6__HN= and tested on \verb=5.5-6__HN=.
%
% Oct 24
%   
%   test03 - STA/LTA on phidget data
%
% Oct. 28
%   re-ran Oct. 18 experiments, but now also saved PCA parameters.
%   test 05 - 


%% Android Sensor ROC plot

disp('Oct. 19, test04. GMM LtSt features (2.5,5), train on B, test on A');
load('experiments/Oct19/test04/gmm_ltst_switched.mat');

% get the ROC curve, best parameters, rename, clear the rest

oct19test04_tp = cTP_amplitudes{1};
oct19test04_fp = cFP_amplitudes{1};
disp(['Oct. 19, test04. Max AUC: ' num2str(maxAUC)])

%clearvars -except 'oct19test04_tp' 'oct19test04_fp' 
clearvars -except 'oct*'


% ------------------------------------------------------------------------

disp('Oct. 19, test03. GMM, XYZ features, train on B, test on A')
load('experiments/Oct19/test03/gm_xyz_switched.mat')

oct19test03_tp = cTP_scales{1};
oct19test03_fp = cFP_scales{1};
disp(['Oct. 19, test03. Max AUC: ' num2str(maxAUC)])

clearvars -except 'oct*'

% ------------------------------------------------------------------------

%disp('Oct. 21, test01. HT, trained with one quake example per SAC file. Trained on 5-6__HN and tested on 5.5-6__HN.')
%load('experiments/Oct21/test01/ht_train_5-6__HN.mat');

load('experiments/Oct24/test01/ht_4.5-5__HN_5-5.5__0-40km__HN.mat');

oct21test01_tp = cTP_amplitudes{1};
oct21test01_fp = cFP_amplitudes{1};
disp(['Oct. 21, test01. Max AUC: ' num2str(maxAUC)])

clearvars -except 'oct*'

% ------------------------------------------------------------------------

disp('Oct. 20, test01. STA/LTA on android data.')
load('experiments/Oct20/test01/StaLta_2.5,5.mat', 'tp', 'fp');
oct24test03_tp = tp;
oct24test03_fp = fp;
clear 'tp' 'fp'

% ------------------------------------------------------------------------

figure()
p = plot(oct19test04_fp, oct19test04_tp, oct19test03_fp, oct19test03_tp, '.--', oct24test03_fp, oct24test03_tp,  oct21test01_fp, oct21test01_tp);

% Will need to replace legend with label arrows
%
legend('GMM LtSt', 'GMM XYZ', 'STA/LTA' ,'Hyp. Test', 'Location', 'SE');

grid on
% changing the text properties of e.g. the plot's title
title('Andoid sensor ROC curves')
h = get(gca, 'title');
set(h, 'FontSize', 16)
set(p,'LineWidth',2)
set(gca, 'FontSize', 16)

%% Phidget sensor ROC plots

clear all;

% ------------------------------------------------------------------------

disp('GMM LtSt on Phidget data')

load('experiments/Oct24/test02/gmm_ltst_2.5s_5s_phidget.mat');
oct24test02_tp = cTP_amplitudes{1};
oct24test02_fp = cFP_amplitudes{1};
clearvars -except 'oct*'

% ------------------------------------------------------------------------

% HT on Phidget Milikan data

% ------------------------------------------------------------------------


disp('Loading Phidget ROC curve')

disp('Oct. 24, test03. STA/LTA on Milikan phidget data.')
load('experiments/Oct24/test03/staLta_phidget.mat', 'tp', 'fp');
oct24test03_tp = tp;
oct24test03_fp = fp;
clear 'tp' 'fp'

% ------------------------------------------------------------------------

figure()
p = plot( oct24test03_fp,  oct24test03_tp, '.-', oct24test02_fp, oct24test02_tp, '.-');

% Will need to replace legend with label arrows
%
legend('STA/LTA', 'GMM LtSt' , 'Location', 'SE');

grid on
% changing the text properties of e.g. the plot's title
title('Phidget sensor ROC curves')
h = get(gca, 'title');
set(h, 'FontSize', 16)
set(p,'LineWidth',2)
set(gca, 'FontSize', 16)


%% Android-Phidget Cell analysis
%
% make 3D plot of maximum cell true positive rate, given numbers of each
% sensor type in a cell, the cell false positive constraint, and the false
% positive constraints for each sensor type.
%
clear

import roc.*

% Parameters:

N_Android = 0:50000:100000; % range of values for the number of androids
N_Phidget = 0:2:10; % range of values for the number of phidgets

secondsInaYear = 31556926;
timeStep = 2.5; % seconds
falsePositivesPerYear = 1;

% limit on cell false positive rate
cFpMax = falsePositivesPerYear * (timeStep / secondsInaYear); 

secondsInaDay = 86400;
androidMessagesPerDay = 192;

% limit on android false positive rate
aFpMax =  androidMessagesPerDay * (timeStep / secondsInaDay); 

phidgetMessagesPerDay = 192;

pFpMax = phidgetMessagesPerDay * (timeStep / secondsInaDay);

FaultRates = [0.1, 0.1];

fprintf('----------------------------------------------\n')
fprintf('cell FP per year: %d\n', falsePositivesPerYear)
fprintf('cell max FP: %1.9f\n\n', cFpMax);

fprintf('Android FP per day: %d\n', androidMessagesPerDay)
fprintf('Android max FP: %f\n\n', aFpMax);

fprintf('Phidget FP per day: %d\n', phidgetMessagesPerDay)
fprintf('Phidget max FP: %f\n\n', pFpMax);

fprintf('Fault Rates, Android: %f,  Phidget: %f\n\n' ,FaultRates(1), FaultRates(2));
fprintf('----------------------------------------------\n')

% ------------------------------------------------------------------------


% disp('Oct. 19, test03. GMM, XYZ features, train on B, test on A')
% load('experiments/Oct19/test03/gm_xyz_switched.mat', 'cTP_scales', 'cFP_scales')
% 
% oct19test03_tp = cTP_scales{1};
% oct19test03_fp = cFP_scales{1};
% 
% android_roc = ReceiverOperatingCharacteristic(oct19test03_tp, oct19test03_fp);
% clear 'oct19test03_tp', 'oct19test03_fp';


disp('GMM LtSt on Android data')

disp('Oct. 19, test04. GMM LtSt features (2.5,5), train on B, test on A');
load('experiments/Oct19/test04/gmm_ltst_switched.mat', 'cTP_amplitudes', 'cFP_amplitudes');
oct19test04_tp = cTP_amplitudes{1};
oct19test04_fp = cFP_amplitudes{1};

android_roc = ReceiverOperatingCharacteristic(oct19test04_tp, oct19test04_fp);
clear 'oct19test04_tp', 'oct19test04_fp';

fprintf('----------------------------------------------\n')


disp('GMM LtSt on Phidget data')

load('experiments/Oct24/test02/gmm_ltst_2.5s_5s_phidget.mat', 'cTP_amplitudes', 'cFP_amplitudes');
oct24test02_tp = cTP_amplitudes{1};
oct24test02_fp = cFP_amplitudes{1};
clear 'cTP_amplitudes' 'cFP_amplitudes'

phidget_roc = ReceiverOperatingCharacteristic(oct24test02_tp, oct24test02_fp);
clear 'oct24test02_tp' 'oct24test02_fp';

fprintf('----------------------------------------------\n')


% ------------------------------------------------------------------------

% plot the ROC curves


if matlabpool('size')==0
    try
        matlabpool open
    catch exception
        disp('Exception opening matlab pool')
        disp(exception)
    end
end



sRoc = cell(2,1);
sRoc{1} = android_roc;
sRoc{2} = phidget_roc;

% ------------------------------------------------------------------------

% constraints


maxSfp = [aFpMax; pFpMax];

maxCellFalsePositive = cFpMax;

% ------------------------------------------------------------------------

% range of number of sensors

NA = N_Android;
NB = N_Phidget;

% ------------------------------------------------------------------------

% ------------------------------------------------------------------------

% loop over the number of sensors, computing system true and false positive
% values.

% prepare for parallelization:
params = cell(length(NA)*length(NB),1);

for i=1:length(NA)
    for j=1:length(NB)
        p.nA = NA(i);
        p.nB = NB(j);
        index = sub2ind([length(NA), length(NB)], i, j);
        params{index} = p;
    end
end

% ------------------------------------------------------------------------

bestTPRValues = zeros(length(params),1);
disp('main loop...')
parfor i=1:length(params)
    import aggregate.*
    import roc.*
    
    p = params{i};
    nA = p.nA;
    nB = p.nB;
    
    N = [nA; nB];
    
    [ TPR, FPR, SensorTP, SensorFP ] = ...
        optimizeCellTwoTypes(N, sRoc, maxSfp, maxCellFalsePositive, FaultRates);
    
    % find maximum TPR value
    maxTPR = max(TPR(:));
    bestTPRValues(i) = maxTPR;
    
    % find corresponding FPR and sensor operating points
end

% plot TPR values.

bestTPRValues = reshape(bestTPRValues, length(NA), length(NB));

surf(NA, NB, bestTPRValues')
axis([0 max(NA) 0 max(NB) 0,1])
xlabel('Number of Androids')
ylabel('Number of Phidgets')
zlabel('Detection Rate')
title('Two-sensor-types Cell performance')


% view([-45 45]) % at-corner view

saveFig = false;

if saveFig
    saveas(gcf, 'android_phidget_cell_surface.fig');
    saveas(gcf, 'android_phidget_cell_surface.png');
end

saveOverhead = false;

if saveOverhead
    colorbar
    % view([0 90]) % overhead view
    view([90 -90]) % overhead, phidgets horizontal, androids vertical
    saveas(gcf, 'android_phidget_cell_surface_alternate.fig');
    saveas(gcf, 'android_phidget_cell_surface_alternate.png');

end

save('android_phidget_cell_surface.mat')

%% Make single sensor type (Android) cell-level ROC plots
% as a function of N

import aggregate.*
import roc.*

% parameters

nAndroid = [10,20, 40, 70, 100];

secondsInaYear = 31556926;
timeStep = 2.5; % seconds
falsePositivesPerYear = 48;

% limit on cell false positive rate
cFpMax = falsePositivesPerYear * (timeStep / secondsInaYear); 

secondsInaDay = 86400;

% below 720, XYZ features are better than LtSt, but LtSt is again better
% for less than maybe 50
androidMessagesPerDay = 700; 

% limit on android false positive rate
aFpMax =  androidMessagesPerDay * (timeStep / secondsInaDay); 


fprintf('----------------------------------------------\n')
fprintf('cell FP per year: %d\n', falsePositivesPerYear)
fprintf('cell max FP: %1.9f\n\n', cFpMax);

fprintf('Android FP per day: %d\n', androidMessagesPerDay)
fprintf('Android max FP: %f\n\n', aFpMax);

fprintf('----------------------------------------------\n')


% Load ROC curve

useXYZ = false;
if useXYZ
    
    disp('Oct. 19, test03. GMM, XYZ features, train on B, test on A')
    load('experiments/Oct19/test03/gm_xyz_switched.mat', 'cTP_scales', 'cFP_scales')
    
    oct19test03_tp = cTP_scales{1};
    oct19test03_fp = cFP_scales{1};
    
    android_roc = ReceiverOperatingCharacteristic(oct19test03_tp, oct19test03_fp);
    clear 'oct19test03_tp', 'oct19test03_fp';
    
else
    
    disp('GMM LtSt on Android data')
    
    disp('Oct. 19, test04. GMM LtSt features (2.5,5), train on B, test on A');
    load('experiments/Oct19/test04/gmm_ltst_switched.mat', 'cTP_amplitudes', 'cFP_amplitudes');
    oct19test04_tp = cTP_amplitudes{1};
    oct19test04_fp = cFP_amplitudes{1};
    
    android_roc = ReceiverOperatingCharacteristic(oct19test04_tp, oct19test04_fp);
    clear 'oct19test04_tp', 'oct19test04_fp';
    
end

fprintf('----------------------------------------------\n')



cCellRoc = cell(length(nAndroid),1);
TP = zeros(length(nAndroid),1);
FP = zeros(length(nAndroid),1);
SensorTP = zeros(length(nAndroid),1);
SensorFP = zeros(length(nAndroid),1);

for i=1:length(nAndroid)
    n = nAndroid(i);
    
    [ tp, fp, cellROC, sensorTP, sensorFP] = ...
        optimizeCellTruePositive( n, android_roc, aFpMax, cFpMax);
    
    fprintf('tp: %f, fp: %f\n', tp, fp);
    
    cCellRoc{i} = cellROC;
    TP(i) = tp;
    FP(i) = fp;
    SensorTP(i) = sensorTP;
    SensorFP(i) = sensorFP;
    
end

%
% plot all the ROC curves on the same figure.
%
% Could put the true positive and false positive rates into matrices, and
% plot. I'm not sure how to get different line styles for each curve.
%
% Could also use hold on, but then I think it will be harder to get the
% legend right (but I may use arrows to label curves, rather that legends

figure()
for i=1:length(nAndroid)
   roc = cCellRoc{i};
   tpr = roc.truePositiveRates;
   fpr = roc.falsePositiveRates;
   plot(fpr,tpr)
   hold on
end
title('Fusion ROC for N Android')
xlabel('False Alarm Rate')
ylabel('Detection Rate')


% format axes
% create legend

%% 


