%% Evaluate cell performance wor two sensor types

% plot the cell-level performance, as a function of the number of each type
% of sensor.


if matlabpool('size')==0
    try
        matlabpool open
    catch exception
        disp('Exception opening matlab pool')
        disp(exception)
    end
end

import aggregate.*
import roc.*


% ------------------------------------------------------------------------

% load sensor ROC curves:

% sRocA
% sRocB

% make some ROC curves
% sensor ROC curve:
tpr = [0; 0.3; 0.5; 0.6; 0.7; 0.8; 0.9; 1];
fpr = [0; 0.1; 0.2; 0.3; 0.4; 0.5; 0.7; 1];
sRocA = ReceiverOperatingCharacteristic(tpr, fpr);

% sensor ROC curve:
tpr = [0; 0.3; 0.5; 0.6; 0.7; 0.8; 0.9; 1];
fpr = [0; 0.1; 0.2; 0.3; 0.4; 0.5; 0.7; 1];
sRocB = ReceiverOperatingCharacteristic(tpr, fpr);

sRoc = cell(2,1);
sRoc{1} = sRocA;
sRoc{2} = sRocB;

% ------------------------------------------------------------------------

% constraints

maxSfpA = 0.1;
maxSfpB = 0.1;

maxSfp = [maxSfpA; maxSfpB];

maxCellFalsePositive = 0.01;

% ------------------------------------------------------------------------

% range of number of sensors

NA = 0:5:25;
NB = 0:5:25;

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

parfor i=1:length(params)
    import aggregate.*
    import roc.*
    
    p = params{i};
    nA = p.nA;
    nB = p.nB;
    
    N = [nA; nB];
    
    [ TPR, FPR, SensorTP, SensorFP ] = ...
        optimizeCellTwoTypes(N, sRoc, maxSfp, maxCellFalsePositive);
    
    % find maximum TPR value
    maxTPR = max(TPR(:));
    bestTPRValues(i) = maxTPR;
    
    % find corresponding FPR and sensor operating points
end

% plot TPR values.

bestTPRValues = reshape(bestTPRValues, length(NA), length(NB));

surf(NA, NB, bestTPRValues)


matlabpool close