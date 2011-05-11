function [ combinedRecord ] = combineShakeTableRecordings( eRecord, nRecord, zRecord, w1, w2, threshold, channel )
% combineShakeTableRecordings - merge single-axis acceleration recordings
% (as produced by the shake table experiments) into one PhoneRecord
% objects.
%
% The recorded "event" is identified by detecting the first time that the
% amplitude of each input record goes above the threshold. w1 seconds
% before
% the event, and w2 seconds after the event are extracted. These events are
% merged into one PhoneRecord
%
% Input:
%   eRecord - PhoneRecord object
%   nRecord - PhoneRecord object
%   zRecord - PhoneRecord object
%   w1 - seconds of 'event' before threshold
%   w2 - seconds of 'event' after threshold
%   threshold - m/s^2
%   channel - which of the input records' channels recorded the
%       acceleration.
%
% Output:
%   combinedRecord - PhoneRecord object

import phone.*
import timeSeries.*

% get events 

sampleRate = eRecord.sampleRate;

% trim the first second off of each record:
eRecord = trimNSeconds(eRecord,1);
nRecord = trimNSeconds(nRecord,1);
zRecord = trimNSeconds(zRecord,1);

eEvent = getEvent(eRecord, sampleRate, w1, w2, threshold, channel);
nEvent = getEvent(nRecord, sampleRate, w1, w2, threshold, channel);
zEvent = getEvent(zRecord, sampleRate, w1, w2, threshold, channel);

% TODO: check for nulls

% merge: interpolate the recordings for consistency.

signalLength = w1+w2; % seconds
desiredPeriod = 1 / sampleRate;

sampleTimes = transpose(0:desiredPeriod:(signalLength-1));

eSamples = eEvent.interpolatedValues(sampleTimes);
nSamples = nEvent.interpolatedValues(sampleTimes);
zSamples = zEvent.interpolatedValues(sampleTimes);

samples = [eSamples; nSamples; zSamples];

% convert to a phone record 
data = [samples; sampleTimes'];

combinedRecord = PhoneRecord('combined', sampleRate, data);

end

function event = getEvent(record, sampleRate, w1, w2, threshold, channel)
%
import phone.*
import timeSeries.*

data = record.data(channel,:);
timeSeries = UniformTimeSeries(data, sampleRate, 0);
event = timeSeries.getOnset(w1, w2, threshold);
end

function record = trimNSeconds(phoneRecord, n)
% trimNSeconds - trim the first n seconds off of a PhoneRecord
    import phone.*
    import timeSeries.*
    
    data = phoneRecord.data;
    sampleRate = phoneRecord.sampleRate;
    
    pointsToTrim = ceil(n*sampleRate);
    
    % TODO: check that the record is long enough?
    
    trimmedData = data(:, pointsToTrim:end);
    record = phoneRecord;
    record.data = trimmedData;
end