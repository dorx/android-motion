function [ reductdata ] = reduction2(rawData, itLength, itStart, niter)

%{ 
Reduce raw data to 3 dimensions for each interval (itLength seconds):
  (1)  mean of the acceleratoion magnitude
  (2)  standard deviation of the acceleratoion magnitude
  (3)  average energy. That is, the magnitude of FFT frequency performed 
          on the acceleratoion magnitude.

Required Arguments:
  rawData: a loaded data file. see Example Use below.

Optional Arguments:
  itLength : number of seconds per interval window (default is 5 seconds)
  niter : number of intervals (default is to exhaust the entire dataset)
  itStart : number of seconds to discard at the beginning of rawData
            (default is 10 seconds)

Review:
  This function could probably be vectorized for efficiency, BUT
  since it needs to be converted to Java later, there's little reason to
  do so.

Example Use:
  rawData = load('C:\Users\AlexFandrianto\Documents\MATLAB\CS141\BackProp\Dat
  a\Alex_walking_04051545.acsn');
  reductdata = reduction2(rawData, 20, 2, 650, 100)
  The resulting reductdata matrix has dimensions: niter x 3
  
%}


% --------------------- Codes start here -------------------

% Find number of lines per second (linesPerSec) of the recording. Since the 
% frequency is not constant throughout, linesPerSec is an average over the  
% entire recording.
datalen = length(rawData);
totalDuration = (rawData(datalen,4) - rawData(1,4)) * 10^(-9); % in second
linesPerSec = datalen / totalDuration; % the number of lines in recording per second


% Invoke default values when the optional arguments are not supplied

if nargin ~= 1 && nargin ~= 4, 
   error('usage: reduction2(rawData) or reduction2(rawData, itLength, itStart, niter)');
end

if nargin == 1,
    itLength = 5;   % Default itLength to 5 seconds interval
    itStart = 10;   % Discard the first 10 seconds of data
    niter = floor(datalen / (itLength * linesPerSec)) - 4; 
                    % Consider the entire dataset except the last 10 seconds
end



A = rawData;

reductdata = zeros(niter, 3);

startline = int32(itStart * linesPerSec + 1);

for i = 1 : niter,
    
    % Line "startline" to line "endline" is an itLength (seconds) interval. 
    startline = startline + itLength * linesPerSec;
    endline = startline + itLength * linesPerSec;
    
    % Extract the interval segment from A (rawData)
    segmentA = A(startline : endline, :);
    
    % Get "magnitude of A": Combine all 3 frequencies using sqrt of sum of squares
    % take the mean, std, and energy. Energy is found by squaring each
    % frequency's amplitude divided by the number of freqs. Skip corr.
    Amag = sqrt(segmentA(:, 1).^2 + segmentA(:, 2).^2 + segmentA(:, 3).^2);
    
    fA = abs(fft(Amag));
    reductdata(i, :) = [mean(Amag), std(Amag), sum(fA.^2) / length(fA)];
    
end

% Since the mean is ~10, and the standard deviation is ~1 while 
% average energy is ~10^5, we do the following scaling so that 
% all components fall in [0.5, 10]:
reductdata = [reductdata(:, 1) / 10, reductdata(:, 2), reductdata(:, 3) / 10^5];

end

