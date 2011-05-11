function [ tpr, fpr, thresholds ] = computeCellRocTwoTypes(nA, nB, tpA, fpA, tpB, fpB)
% cellROC - sweep thresholds for each type of sensor, and determine cell
% performance.
%
% Input:
%   nA - number of sensors of type A in cell
%   nB - number of sensors of type B in cell
%   tpA - sensor type A true positive rate
%   fpA - sensor type A false positive rate
%   tpA - sensor type B true positive rate
%   fpA - sensor type B false positive rate
%
% Output:
%   tpr - column vector of true positive rates
%   fpr - column vector of false positive rates
%   thresholds
%
% Old Output:
%    tpr - (nA+1,nB+1) matrix. entry (i,j) is the true positive rate for i
%       sensors of type A, j sensors of type B.
%    fpr - (nA+1,nB+1) matrix. entry (i,j) is the false positive rate for i
%       sensors of type A, j sensors of type B.
%   
% author: Matt Faulkner
%
% TODO: try sub2ind to avoid reshaping matrices
%
import aggregate.*
import roc.*

assert(0 <= tpA);
assert(tpA <= 1);

assert(0 <= tpB);
assert(tpB <= 1);

assert(0 <= fpA);
assert(fpA <= 1);

assert(0 <= fpB);
assert(fpB <= 1);


% r* is the number of sensors of type * that report a pick 
%
% P(rA,rB | "quake", nA, tpA, fpA, nB, tpB, fpB ) = binom(rA; nA, tpA ) *
%   binom(rB; nB, tpB);
% P(rA,rB | " no quake", nA, tpA, fpA, nB, tpB, fpB ) = binom(rA; nA, fpA ) *
%   binom(rB; nB, fpB);
% 

% compute all possbile likelihood ratios

eventLikelihoods = zeros(nA+1, nB+1); % P(R | "event")
nonEventLikelihoods = zeros(nA+1, nB+1); % P(R | "no event")

likelihoodRatios = zeros(nA+1, nB+1);

for i = 1:nA+1 
    for j = 1:nB+1 
        
        a = i-1;   % a sensors of type A report, 0 <= a <= nA
        b = j-1; % b sensors of type B report
        
        %fprintf('a: %d, b: %d\n', a,b);
        
        eventP = binopdf(a, nA, tpA) * binopdf(b, nB, tpB);
        
        nonEventP = binopdf(a, nA, fpA) * binopdf(b,nB, fpB);
        
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




% tpr = zeros(nA+1,nB+1);
% fpr = zeros(nA+1,nB+1);
% 
% % loop over possible threshold values: I don't think this is correct: I
% % should form the likelihood ratio of P(R | quake) / P(R | no quake) for
% % each set of possible observations, then sweep a threshold. 
% %
% for tA = 0:nA %thresholds on A
%     for tB = 0:nB %thresholds on B
%         
%         
%         % X = P( rA > tA, rB > tB | "quake" ...)
%         X = 1 - binocdf(tA, nA, tpA) * binocdf(tB, nB, tpB);
%         
%         %  Y = P( rA > tA, rB > tB | "no quake" ...)
%         Y = 1 - binocdf(tA, nA, fpA) * binocdf(tB, nB, fpB);
%         
%         tpr(tA+1,tB+1) = X;
%         fpr(tA+1,tB+1) = Y;
%     end
% end
% 
% tpr = reshape(tpr, size(tpr,1)*size(tpr,2), 1);
% fpr = reshape(fpr, size(fpr,1)*size(fpr,2), 1);



end