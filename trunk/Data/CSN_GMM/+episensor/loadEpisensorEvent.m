function events = loadEpisensorEvent( epiScript, w1, w2, threshold)
% loadEpisensorEvent - load an EpiSensor recording, convert units, and
%   segment out the event.
%
% Input:
%   epiScript - path to an EpiSensor-produced matlab script. This is
%      correctly set if 'run epiScript' works at the command prompt
%   w1 - time before the event to return
%   w2 - time after the event to return
%   threshold - m/s^2 to detect an event
%
% Output:
%   events - cell array of UniformTimeSeries object, possibly empty
%
% Throws an exception if no event is detected
%
% author: Matt Faulkner
%

import timeSeries.*


loadCommand = ['run ' epiScript];
eval(loadCommand);

% EpiSensor acceleration, converted to m/s^2
episensorData = Ch_3_C3 * 9.8* 4 / (2^23);
episensorData = episensorData -mean(episensorData);


sps = Ch_3_C3_SPS;  % samples per second:
% 
% nDataPoints = length(episensorData);
% t = (1:nDataPoints) / sps;

uTS = UniformTimeSeries(episensorData, sps, 0);

events = cell(0,0);

[event, rest] = uTS.getOnset( w1, w2, threshold);

if isempty(event)
    err = MException('loadEpisensorEvent:noEventDetected', ...
        'No event was detected.');
    throw(err)
end

events{1} = event;

% try to segment the rest
while ~isempty(rest)
    [event, rest] = rest.getOnset(w1, w2, threshold);
    events{end+1} = event; 
end

end

