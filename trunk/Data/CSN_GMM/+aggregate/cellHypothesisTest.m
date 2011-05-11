function [E, LR] = cellHypothesisTest( s, N, sensorTpr, sensorFpr, tau)
% cellHypothesisTest - perform the cell level hypothesis test on the number
% of picks, for one sensor type, assuming binomial distributions
%
% Input:
%   s - number of pick messages sent
%   N - number of sensors in the cell
%   sensorTpr - sensor true positive rate
%   sensorFpr - sensor fales positive rate
%   tau - cell threshold on likelihood ratio
%       (should I use log likelihood ratios?)
%
% Output:
%   E - 1 if an event is thought to have occurred; 0 otherwise
%   LR - likelihood ratio
% 
% author: Matt Faulkner
%
import check.*

assert( (0 <= sensorTpr) && (sensorTpr <= 1) )
assert( (0 <= sensorFpr) && (sensorFpr <= 1) )

assert(isNonNegativeScalar(s))
assert(isNonNegativeScalar(N))
assert(s <= N)


numer = binopdf(s, N, sensorTpr);
denom = binopdf(s, N, sensorFpr);

LR = numer / denom;

E = ( LR > tau);


end

