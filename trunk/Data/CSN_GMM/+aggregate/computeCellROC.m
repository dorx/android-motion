function [ cellROC ] = computeCellROC(N, truePositiveSensor, falsePositiveSensor)
% cellROC - compute the ROC for cell-level aggregation.
%
% Input:
%   N - number of active sensors in cell
%   truePositiveSensor - true positive rate for each sensor
%   falsePositiveSensor - false positive rate for each sensor
% 
% Output:
%   cellROC - ReceiverOperatingCharacteristic object   
%
import aggregate.*
import roc.*

% Compute thresholds
% tau - threshold on X above which the cell declares an event
Tau = (0:N)';

% the number of reported picks R is assumed distributed according to a
% the conditional distributions (tp is truePositiveSensor, fp is falsePositiveSensor)
% P(R | "quake", N, tp, fp) = binom(R; N, tp )
% P(R | "no quake", N, tp, fp) = binom(R; N, fp )
%
% it is assumed that tp > fp

TPR = 1-binocdf(Tau, N, truePositiveSensor); % density above the threshold
TPR = [0;TPR;1];

FPR = 1-binocdf(Tau, N, falsePositiveSensor); 
FPR = [0;FPR;1];

% NOTE: the gaussian approximation to the binomial might be useful.

% sort
%[FPR, I] = sort(FPR);
%TPR = TPR(I);

% compute the likelihood ratios for each value of tau:




numer = binopdf(Tau, N, truePositiveSensor);
denom = binopdf(Tau, N, falsePositiveSensor);

thresholds = numer ./ denom;
% TODO: check for nans or infs, which could occur for edge-case inputs,
% like 0,1 probabilities or N = 0
%
% extend, to be the same length as TPR, FPR
thresholds = [thresholds(end); thresholds; thresholds(1)];

cellROC = roc.ReceiverOperatingCharacteristic(TPR, FPR, thresholds);

end





