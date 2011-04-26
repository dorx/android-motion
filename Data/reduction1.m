function [ data ] = reduction1( rawData, iterations, itStart, itLength, NFFT )
%reduction1 Alex's first simple reduction
%   Compute acceleration magnitudes
%   Then take the mean accel and std accel
%   Use FFT to get freq amplitudes and the resulting energy of signal
%   Example Use:
%   rawData = load('C:\Users\AlexFandrianto\Documents\MATLAB\CS141\BackProp\Dat
%   a\Alex_walking_04051545.acsn');
%   data = reduction1(rawData, 20, 2, 650, 100)
%   The data matrix has dimensions: iterations x 3

%   This function could probably be vectorized for efficiency, BUT
%   since it needs to be converted to Java later, there's little reason to
%   do so.

%   The reduction also attempts to make everything learnable with my
%   sigmoid. So it reduces every value by 10000.

A = rawData;

data = zeros(iterations, 3);

for i=1:iterations
    segmentA = A(itLength * (itStart) + 1: itLength * (itStart+1), :);
    
    % Combine all 3 frequencies using sqrt of sum of squares
    % take the mean, std, and energy. Energy is found by squaring each
    % frequency's amplitude divided by the number of freqs. Skip corr.
    
    sA = sqrt(segmentA(:, 1).^2 + segmentA(:, 2).^2 + segmentA(:, 3).^2);
    
    NFFT = 100;
    
    fA = abs(fft(sA,NFFT));
    
    data(i, :) = [mean(sA), std(sA), sum(fA.^2) / length(fA)];
    
end

data = data / 10000;



end

