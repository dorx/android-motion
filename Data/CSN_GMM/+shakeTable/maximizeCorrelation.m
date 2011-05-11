function maxC = maximizeCorrelation(timeSeriesA, timeSeriesB, maxShift)
%   maximizeCorrelation - maximize the correlation between two
%       UniformTimeSeries objects, via resampling and shifting
%       
%
% Input:
%   timeSeriesA - UniformTimeSeries object
%   timeSeriesB - UniformTimeSeries object
%   maxShift - maximum amount (seconds) to shift A relative to B
%
% Output:
%   cor - maximum absolute correlation coefficient
%
% author: Matt Faulkner
%

import timeSeries.*

assert(isa(timeSeriesA, 'UniformTimeSeries'));
assert(isa(timeSeriesB, 'UniformTimeSeries'));

% match sampling rates: upsample the record of lower sampling rate?
% 
% determine how much to shift
% for each shift
%   trim off mismatch
%   compute correlation coefficient
%

sampleRateA = timeSeriesA.Fs;
sampleRateB = timeSeriesB.Fs;

% resample to max sample rate:

if sampleRateA > sampleRateB
   timesA = timeSeriesA.getTimes();
   sampleRate = timeSeriesA.Fs;
   newBVals = timeSeriesB.interpolatedValues(timesA);
   timeSeriesB = UniformTimeSeries(newBVals, timeSeriesB.Fs,  timeSeriesB.startTime);
else
   timesB = timeSeriesB.getTimes();
   sampleRate = timeSeriesB.Fs;
   newAVals = timeSeriesA.interpolatedValues(timesB);
   timeSeriesA = UniformTimeSeries(newAVals, timeSeriesA.Fs,  timeSeriesA.startTime);
end

% these should now have the same number of points, and the same duration

assert(isa(timeSeriesA, 'UniformTimeSeries'));
assert(isa(timeSeriesB, 'UniformTimeSeries'));
assert(size(timeSeriesA.X, 2) == size(timeSeriesB.X, 2));

% extract the data, and perform shift

% these should be row vectors
dataA = timeSeriesA.X; 
dataB = timeSeriesB.X;

% this should have been done earlier, but just in case
dataA = dataA - mean(dataA);
dataB = dataB - mean(dataB);

numShifts = floor(maxShift * sampleRate);

% initialize the max-so-far with the unshifted correlation
corMatrix = abs(corrcoef(timeSeriesA.X, timeSeriesB.X));
maxC = corMatrix(1,2); % grab an off-diagonal entry


for i=1:numShifts
    aShift = dataA(i:end);
    lengthA = length(aShift);
    bTrim = dataB(1:lengthA);
    
    cMatrix = corrcoef(aShift, bTrim);
    % take an off-diagonal
    c = abs(cMatrix(1,2));
    if c > maxC
        maxC = c;
    end
end

% shift B forward relative to A
for i=1:numShifts
    bShift = dataB(i:end);
    lengthB = length(bShift);
    aTrim = dataA(1:lengthB);
    
    cMatrix = corrcoef(bShift, aTrim);
    % take an off-diagonal
    c = abs(cMatrix(1,2));
    if c > maxC
        maxC = c;
    end
end


end