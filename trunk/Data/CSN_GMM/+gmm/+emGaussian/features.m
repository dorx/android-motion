function featureMat = features(data, fftn, moments)
% features(data)
% Input:
%   data    - An n x 4 matrix, where each row is (x, y, z, t)
%   fftn    - Number to go up to in the fft (fft(data, n))
%   moments - Number of moments to include. Starts from the 2nd moment
%
% Output:
%   featureMat - A vector of all features

s = size(data);
length = s(1);

% Do a fourier transform, assuming that the data is uniformly sampled.
% This isn't so bad, the standard deviation of the sampling rate is
% orders of magnitude smaller than the rate itself.
NFTT = max([fftn length]);
xyz  = data(:, 1:3);
fftc = fft(xyz, NFTT) / length; 
fftc = abs(fftc(1:fftn,1:3));

% Get the moments on each axis, excluding the first moment
mom = [];
for i = 2 : moments+1
    mom = [mom; moment(xyz, i)];
end

featureMat = [fftc; mom];

% Transform from matrix to vector, putting the top-left element first, then
% proceeding along the first row, and so on.
temp = featureMat';
featureMat = temp(:);

end

