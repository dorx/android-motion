function [ tpr, fpr, thresholds ] = cellRocTwoTypes(N, TP, FP, FaultRates)
% cellRocTwoTypes - computes the cell ROC curve, for given numbers of two
% different types of sensors. Each sensor type can have a "faulty" rate.
%
% This is an adaptation of the earlier function 'computeCellRocTwoTypes'.
%
% Input:
%   N - 2x1 column vector. Number of each type of sensor.
%   TP - 2x1 column vector. True positive rates for each sensor.
%   FP - 2x1 column vector. False positive rates for each sensor.
%   FaultRates - 2x1 column vector. Rate at which each sensor type "faults"
%       and operates at tp = 0.5, fp = 0.5
%
% Output:
%
% author: Matt Faulkner
%


import aggregate.*
import check.*
import roc.*

% ------------------------------------------------------------------------

nA = N(1);
nB = N(2);

tpA = TP(1);
tpB = TP(2);

fpA = FP(1);
fpB = FP(2);

faultRateA = FaultRates(1);
faultRateB = FaultRates(2);

assert(0 <= tpA);
assert(tpA <= 1);

assert(0 <= tpB);
assert(tpB <= 1);

assert(0 <= fpA);
assert(fpA <= 1);

assert(0 <= fpB);
assert(fpB <= 1);

% ------------------------------------------------------------------------

eventLikelihoods = zeros(nA+1, nB+1); % P(R | "event")
nonEventLikelihoods = zeros(nA+1, nB+1); % P(R | "no event")

likelihoodRatios = zeros(nA+1, nB+1);

for i = 1:nA+1
    for j = 1:nB+1
        
        a = i-1;   % a sensors of type A report, 0 <= a <= nA
        b = j-1; % b sensors of type B report
        
        % Bug: this says that with some fault rate, ALL sensors of a type
        % fault.
        %eventP = ((1-faultRateA)*binopdf(a, nA, tpA) + faultRateA*binopdf(a,nA,0.5))* ((1-faultRateB)*binopdf(b, nB, tpB) + faultRateB*binopdf(b,nB,0.5));
        
        %nonEventP = ((1-faultRateA)*binopdf(a, nA, fpA) + faultRateA*binopdf(a,nA,0.5)) * ((1-faultRateB)*binopdf(b,nB, fpB) + faultRateB*binopdf(b,nB, 0.5));
        
        % with some rate, EACH sensor faults to the operating opint (0.5,
        % 0.5), which changes its effective operating point:
        %
        effectiveTpA = (faultRateA * 0.5) + (1-faultRateA)*tpA;
        effectiveFpA = (faultRateA * 0.5) + (1-faultRateA)*fpA;
        
        effectiveTpB = (faultRateB * 0.5) + (1-faultRateB)*tpB;
        effectiveFpB = (faultRateB * 0.5) + (1-faultRateB)*fpB;
        
        
        eventP = binopdf(a, nA, effectiveTpA) * binopdf(b, nB, effectiveTpB);
        
        nonEventP = binopdf(a, nA, effectiveFpA) * binopdf(b, nB, effectiveFpB);
        
        eventLikelihoods(i,j) = eventP;
        nonEventLikelihoods(i,j) = nonEventP;
        
        likelihoodRatios(i,j) = eventP / nonEventP;
    end
end

% loop over threshold values, and compute true positive, false positive
% values

thresholds = unique(likelihoodRatios(:));

tpr = zeros(length(thresholds), 1);
fpr = zeros(length(thresholds), 1);

for i=1:length(thresholds)
   eta = thresholds(i);
   
   % find all a,b values for which the likelihood ratio is >= eta
   
   indices = find(likelihoodRatios > eta);
   
   eventP = eventLikelihoods(indices);
   nonEventP = nonEventLikelihoods(indices);
   
   % A = aVals(indices);
   % B = bVals(indices);
   
   % for each 
    
   pd = sum(eventP); % probability of detection aka true positive rate
   pf = sum(nonEventP); % probability of false alarm aka false positive rate
   
   tpr(i) = pd;
   fpr(i) = pf;
   
end

