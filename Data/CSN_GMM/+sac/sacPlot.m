function h =  sacPlot(sacFile)
% sacPlot - plot a SAC file
%
% Input:
%   sacFile - path to a SAC file (optional)
%
% Output:
%   h - figure handle
%
import sac.*
import check.*

if nargin == 0
    [sacName, pathName] = uigetfile('.sac');
    sacFile = [pathName sacName];
end

if ~isFile(sacFile, 'sac')
    error([sacFile ' cannot be found or is not a sac file.'])
end

sacWaveform = SacWaveform(sacFile);

% maybe display some header information?

h= figure();

times = sacWaveform.getTimeSeries.getTimes; % in seconds
accel = sacWaveform.accel;

plot(times, accel);
xlabel('seconds')
ylabel('m/s^2')

end