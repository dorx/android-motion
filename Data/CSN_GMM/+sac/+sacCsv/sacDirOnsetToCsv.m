function  sacDirOnsetToCsv(w1, w2, threshold, rootDir)
%   sacDirOnsetToCsv - get onsets of SAC records, and write each channel to
%   csv
%
% Input:
%   w1 - length before onset. Seconds
%   w2 - length after onset. Seconds
%   threshold - for onset detection. m/s^2
%   rootDir - path to a directory of SAC channel directories (optional)
%

import sac.*
import sac.sacCsv.*
import check.*


if nargin == 3
    rootDir = uigetdir();
end

assertDirectory(rootDir);

cSacRecords = SacLoader.loadSacRecords(rootDir);

% sort records by increasing peak amplitude

peakAmplitudes = zeros(length(cSacRecords),1);

for i=1:length(cSacRecords)
   sacRecord = cSacRecords{i};
   p = max(sacRecord.getMagnitude());
   peakAmplitudes(i) = p;
end

[peakAmplitudes, I] = sort(peakAmplitudes);
cSacRecords = cSacRecords(I);

% loop over these and write to csv
for i=1:length(cSacRecords)

   sacRecord = cSacRecords{i};
   name = num2str(i);
   
      % display sac waveform names, for the record:
   disp('----------------------------------------------')
   disp(['Sac Record ' num2str(i)]);
   disp(sacRecord.eWaveform.fileName);
   disp(sacRecord.nWaveform.fileName);
   disp(sacRecord.zWaveform.fileName);
   
   sacOnsetToCsv(sacRecord, name, w1, w2,threshold);
end

