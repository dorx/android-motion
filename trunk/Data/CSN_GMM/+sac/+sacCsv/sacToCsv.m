function sacToCsv( sacFile, name )
% sacToCsv - convert a sac file to a CSV file for use with Agilent's
% IntuiLink software.
%
%

import sac.*
import sac.sacCsv.*
import check.*

MAX_LENGTH = 64000; % maximum length of Agilent 33220A arbitrary waveforms

if nargin == 0
    [name, path] = uigetfile('.sac');
    sacFile = [path name];
end

if ~isFile(sacFile, 'sac')
    error([sacFile ' cannot be found or is not a sac file.'])
end

sacWaveform = SacWaveform(sacFile);

% get the data points as a column
accel = sacWaveform.accel;

accel = accel - mean(accel);

% convert from m/s^2 to g:
accel = accel / 9.8;

bigIndices = find(accel > 1);
accel(bigIndices) = 1;

smallIndices = find(accel < -1);
accel(smallIndices) = -1;

% make sure waveform is less than MAX_LENGTH

if length(accel) > MAX_LENGTH
   warning(['accel is longer than MAX_LENGTH. Skipping ' sacFile])
end

% create file name. Maybe incorporate the length of the waveform in
% seconds, and its max absolute amplitude (in m/s^2) for use as parameters
% with the 33220a

waveformLengthSeconds = sacWaveform.lengthSeconds();

filename = sprintf('%s_%5.5fs_%5.5fg.csv', name, waveformLengthSeconds, maxAbs);

% write to CSV
assert(isColumnVector(accel));

csvwrite(filename, accel);

end

