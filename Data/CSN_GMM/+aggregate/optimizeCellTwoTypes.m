function [ TPR, FPR, SensorTP, SensorFP ] = ...
    optimizeCellTwoTypes(N, sRoc, maxSfp, maxCellFalsePositive, FaultRates)
% optimizeCellTwoTypes - optimize the cell-level true positive rate when
% there are two kinds of sensors present, subject to constraints on sensor
% and cell false positive rate.
%
% Input:
%   N - 2x1 column vector. N(1) is number of sensors of type A; N(2) is
%      number of sensors of type B
%   sRoc - 2x1 cell array. sRoc{1} is ReceiverOperatingCharacteristic object
%      for sensor type A; sRoc{2} is the same for type B.
%   maxSfp - 2x1 column vector of maximum sensor dalse positive rates.
%   maxCellFalsePositiveRate - 
%   FaultRates - 2x1 column vector. Rate at which each sensor "faults" to
%       tp=0.5, fp=0.5 performance. (Optional, default [0;0])
%
% 
% Output
%   TPR - maximum obtainable true positive rate for each point on the
%       sensors' operating curves
%   FPR - corresponding false positive rate, for point on the sensors'
%       operating curves
%   SensorTP - each cell is a 2x1 column vector of sensor true positive rates used to
%      obtain the best cell performance
%   SensorFP - each cell is a 2x1 column vector of sensor false positive rates used to
%      obtain the best cell performance
%
% TODO: a better order of computations might be to loop over all cell
% thresholds 0:Na, 0:Nb, and for each threshold, evaluate the best sensor
% operating points, and resulting sensor and cell tp,fp.
%
import aggregate.*
import roc.*
import check.* 


if nargin == 4
    FaultRates = [0;0];
end


% uniformly discretize the sensor ROC curve
nDiscretizations = 100; % <== Magic Number

rocA = sRoc{1};
rocB = sRoc{2};
clear sRoc;

maxFpA = maxSfp(1);
maxFpB = maxSfp(2);

% discretize finely around (0,0)

%fpDiscretize = linspace(0,1, nDiscretizations)'; % must be a column vector
fpDiscretize = logspace(-4,0, nDiscretizations)'; % must be a column vector

tpDiscretizeA = rocA.interpolateTruePositiveRate(fpDiscretize);
tpDiscretizeB = rocB.interpolateTruePositiveRate(fpDiscretize);


% for each admissible point on the sensor ROC curves, compute the cell ROC
% curve, and find the maximum true positive rate

TPR = zeros(nDiscretizations, nDiscretizations);
FPR = zeros(nDiscretizations, nDiscretizations);

SensorTP = cell(nDiscretizations, nDiscretizations);
SensorFP = cell(nDiscretizations, nDiscretizations);

for i=1:nDiscretizations % loop over points on A's ROC
    for j=1:nDiscretizations % loop over points on B's ROC
        
        tpA = tpDiscretizeA(i);
        fpA = fpDiscretize(i);
        
        tpB = tpDiscretizeB(j);
        fpB = fpDiscretize(j);
        
        % check sensor false positive constraints
        if (fpA > maxFpA) || (fpB > maxFpB)
            continue
        end
        
        %fprintf('i: %d, j: %d\n', i, j)
        % compute maximum obtainable cell tp, for these sensor rates:
        %[ tpr, fpr ] = computeCellRocTwoTypes(nA, nB, tpA, fpA, tpB, fpB);
        
        TP = [tpA; tpB];
        FP = [fpA; fpB];
        [ tpr, fpr] = cellRocTwoTypes(N, TP, FP, FaultRates);
        
        % find the maximum value, subject to cell false positive
        % constraints;
        
        [bestTp, bestFp] = bestOperatingPoint(tpr, fpr, maxCellFalsePositive);
        TPR(i,j) = bestTp;
        FPR(i,j) = bestFp;
        SensorTP{i,j} = [tpA; tpB];
        SensorFP{i,j} = [fpA; fpB];
    end
end

end

function [bestTp, bestFp] = bestOperatingPoint(tpr, fpr, fpMax)
    % bestOperatingPoint - find value of highest true positive rate subject
    % to a constraint of the maximum false positive rate. If there are
    % multiple values of fpr for the same best tpr, the lowest fpr rate is
    % returned
    
    badIndices = find(fpr > fpMax);
    tpr(badIndices) = 0; % these are unobtainable.
    
    bestTp = max(tpr);
    I = find(tpr == bestTp);
    
    fpValues = fpr(I);
    bestFp = min(fpValues);
    
    
end

%function [bestTp, bestFp, nA, nB] = bestOperatingPoint(tpr, fpr, fpMax)
% bestOperatingPoint - find highest tpr, with fpr <= fpMax.
%   If there are several identical tpr values with different fpr values,
%   report the lowest fpr.
%
% Input:
%   tpr - matrix of true positive rates
%   fpr - matrix of corresponding false positive rates.
%
% I'd like to return the (i,j) index into tpr and fpr. 
%
% TODO: use the sub2ind method to get matrix subscripts

% 
% [m,n] = size(tpr);
% assert(size(fpr,1) == m);
% assert(size(fpr,2) == n);
% 
% thresholdValues = cell(m,n);
% for i=1:m % nA+1 values
%     for j=1:n % nB+1 values
%         nA = i-1;
%         nB = j-i;
%         thresholds = [nA; nB];
%         thresholdValues{i,j} = thresholds;
%     end
% end
% 
% tpr = reshape(tpr, m*n,1);
% fpr = reshape(fpr, m*n,1);
% thresholdValues = reshape(thresholdValues,m*n,1);
% 
% badIndices = find(fpr > fpMax);
% tpr(badIndices) = 0; % these are unobtainable.
% 
% bestTp = max(tpr);
% I = find(tpr == bestTp);
% 
% fpValues = fpr(I);
% thresholds = thresholdValues(I);
% 
% [bestFp, I] = min(fpValues);
% thresholds = thresholds{I};
% nA = thresholds(1);
% nB = thresholds(2);
% 
% 
% end




