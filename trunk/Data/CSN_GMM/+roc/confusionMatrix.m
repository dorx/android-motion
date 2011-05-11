function [ TPR FPR TNR FNR] = confusionMatrix( predictedLabels, actualLabels )
% confusionMatrix 
%
% Input:
%   predictedLabels - (mx1) vector of +/- 1 values
%   actualLabels - (mx1) vector of +/- 1 values
%
% Output:
%   TPR - True positive rate. Fraction of actually positive labels that were
%       predicted to be positive.
%   FPR - False positive rate. Fraction of actually negative labels that
%       were predicted to be positive.
%   TNR - True Negative Rate. Fraction of actually negative labels that
%       were predicted to be negative.
%   FNR - False Negative Rate. Fraction of actually positive labels that
%       were predicted to be negative.
%
% NOTE: if one of the label values is not represented in the actual or
% predicted labels, divide-by-zero could occur.

positiveIndices = find(predictedLabels > 0);
negativeIndices = find(predictedLabels < 0);

truePositiveIndices = find(actualLabels > 0);
trueNegativeIndices = find(actualLabels < 0);

tp = length(intersect(positiveIndices, truePositiveIndices));
tn = length(intersect(negativeIndices, trueNegativeIndices));
fp = length(intersect(positiveIndices, trueNegativeIndices));
fn = length(intersect(negativeIndices, truePositiveIndices));

TPR = tp / (tp + fn);
FPR = fp / (fp + tn);

TNR = tn / (tn + fp);
FNR = fn / (fn + tp);

    
% --- check outputs to be in [0,1], and not NaN or Inf

% might want to replace NaN and Inf with some acceptable value, like 0 or
% 1.

inZeroOne(TPR);
inZeroOne(FPR);
inZeroOne(TNR);
inZeroOne(FNR);


% assert that 0 <= x <= 1
function [okay] = inZeroOne(x)
    okay = (0 <= x ) && (x <= 1);
    if ~okay
        error(['a rate is not in [0,1] : ' num2str(x)])
    end
