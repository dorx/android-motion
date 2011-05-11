function [TPR, FPR] = ...
    myROC( TrueLabels, Assignments, Thresholds )
% Inputs
%   TrueLabels - (n x 1) vector True labels in {1,2} of the test points
%   Assignments - (n x 1) vector Floating point values assigned to the test
%       points.
%   Thresholds - (t x 1) vector Threshold to assign labels {1,2} to the
%       assignments. Points above the threshold are given 1, below 2.
%
% Outputs
%   TPR - (t x 1) vector. True Positive Ratio
%           TPR = TP / P  = TP / (TP + FN)
%    
%   FPR - (t x 1) vector. False Positive Ratio
%           FPR = FP / N  = FP / (FP + TN)
%
%   An assignment of 1 is considered a "positive", 2 a "negative"
%
%                     x  1, "positive"
%
%  ------------------------------------------ threshold
%
%                 o 2, "negative"
%
% Also see the Matlab function "roc", which I should probably be using

n = length(TrueLabels);
t = length(Thresholds);

assert(length(Assignments) == n);

if any(isnan(Assignments))
   warning('myROC:Assignments contains NaNs') 
end

if any(isinf(Assignments))
   warning('myROC:Assignments contains Infs') 
end


TPR = zeros(t,1);
FPR = zeros(t,1);

parfor i = 1:t
    threshold = Thresholds(i);
    
    % TODO: replace this with a call to confusionMatrix
    
    positiveIndices = find(Assignments > threshold);
    negativeIndices = find(Assignments <= threshold);
    
    truePositives = find(TrueLabels == 1);
    trueNegatives = find(TrueLabels == 2);
    
    % find assignments that are neither 1 or 2
    
    % now evaluate the true/false positive/negative of the assignments
    tp = length(intersect(positiveIndices, truePositives));
    tn = length(intersect(negativeIndices, trueNegatives));
    fp = length(intersect(positiveIndices, trueNegatives));
    fn = length(intersect(negativeIndices, truePositives));
    
    truePositiveRate = tp / (tp + fn);
    falsePositiveRate = fp / (fp + tn);
    
    if isnan(truePositiveRate) || isnan(falsePositiveRate)
       %warning('myROC:converting NaN to 0') 
       fprintf('tp: %f, tn: %f, fp: %f, fn: %f\n', tp, tn,fp,fn);
       
       if isnan(truePositiveRate) || isnan(falsePositiveRate)
          truePositiveRate = 0; 
          falsePositiveRate = 0;
       end
       
    end
    
    TPR(i) = truePositiveRate;
    FPR(i) = falsePositiveRate;
end

% if there are no true positives, and no false negatives, then TPR is 0/0.
% Maybe check for NaN, and replace it with 1?
% if any(isnan(TPR))
%     warning('Converting TPR NaNs to 0.5');
%     TPR(isnan(TPR)) = 0.5;
% end
% 
% if any(isnan(FPR))
%     warning('Converting FPR NaNs to 0.5');
%     FPR(isnan(FPR)) = 0.5;
% end


if max(TPR) > 1
    error(['TPR greater than 1: TPR = ' num2str(max(TPR)) ])
end

if min(TPR) < 0
    error(['TPR negative: TPR = ' num2str(min(TPR))])
end
    
if max(FPR) > 1
    error(['FPR greater than 1: FPR = ' num2str(max(FPR)) ])
end

if min(FPR) < 0
    error(['FPR negative: FPR = ' num2str(min(FPR))])
end

