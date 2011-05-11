function test_suite = testSegmentSynthesizer
clear all; % to reload class definitions
initTestSuite;
% xUnit test suite. Functions must not end with "end" statement.
%
% author: Matt Faulkner

% ------------------------------------------------------------------------

function testSegmentPhoneRecord

import phone.*
import sac.*
import synthetic.*
import check.*
import timeSeries.*

% load up a time series
acsnFile = 'testData/walk.acsn';
sampleRate = 50;

segmentLength = 12; % seconds

phoneRecord = PhoneRecord(acsnFile);
recordLength = phoneRecord.getLength();

cTimeSeries = SegmentSynthesizer.segmentPhoneRecord(phoneRecord, segmentLength, sampleRate);
timeSeries = cTimeSeries{1};

disp(['record length: ' num2str(recordLength)])
disp(['time series length: ' num2str(timeSeries.lengthSeconds())])

assertElementsAlmostEqual(segmentLength, timeSeries.lengthSeconds(), 'absolute', 0.02);

% ------------------------------------------------------------------------

function testSegmentPhoneRecordPadding
%
% verify that a segmentLength longer than the length of the recording
% results in a segment padded with trailing zeros.

import phone.*
import sac.*
import synthetic.*
import check.*
import timeSeries.*

% load up a time series
acsnFile = 'testData/walk.acsn'; % this one is about 12 seconds long
sampleRate = 50;

segmentLength = 20; % seconds

phoneRecord = PhoneRecord(acsnFile);
recordLength = phoneRecord.getLength();

cTimeSeries = SegmentSynthesizer.segmentPhoneRecord(phoneRecord, segmentLength, sampleRate);
timeSeries = cTimeSeries{1};

disp(['record length: ' num2str(recordLength)])
disp(['time series length: ' num2str(timeSeries.lengthSeconds())])

assertElementsAlmostEqual(segmentLength, timeSeries.lengthSeconds(), 'absolute', 1/sampleRate);

% ------------------------------------------------------------------------

function testSegmentSynthesizerBasic
import phone.*
import sac.*
import synthetic.*
import check.*
import timeSeries.*

phoneDir = 'testData/acsnDir';
sacRootDir = 'testData/sacComponents';

cPhoneRecords = PhoneRecord.loadPhoneRecordDir(phoneDir);
cSacRecords = SacLoader.loadSacRecords(sacRootDir);

segmentLength = 2; % seconds
sampleRate = 50; % samples per second
minSeismicAmplitude = 0; % m/s^2
scale = 1;

%

nPhoneRecords = length(cPhoneRecords);
cSegments = {};

for i=1:nPhoneRecords
    phoneRecord = cPhoneRecords{i};
    cNewSegments = SegmentSynthesizer.segmentPhoneRecord(phoneRecord, segmentLength, sampleRate);
    cSegments = [cSegments; cNewSegments];
end

 cTimeSeries = ...
     SegmentSynthesizer.createSyntheticSegments(cSegments, cSacRecords, ...
     segmentLength, sampleRate, minSeismicAmplitude, scale);

% TODO: check that each time series has segmentLength*sampleRate (floored
% or ceiled, I haven't decided) number of samples.

% ------------------------------------------------------------------------

function testSegmentSynthesizerNonIntegerSampleRate
% try a non-integer desired sample rate
import phone.*
import sac.*
import synthetic.*
import check.*
import timeSeries.*

phoneDir = 'testData/acsnDir';
sacRootDir = 'testData/sacComponents';

cPhoneRecords = PhoneRecord.loadPhoneRecordDir(phoneDir);
cSacRecords = SacLoader.loadSacRecords(sacRootDir);

segmentLength = 2; % seconds
sampleRate = 50.3; % samples per second
minSeismicAmplitude = 0; % m/s^2
scale = 1;

%

nPhoneRecords = length(cPhoneRecords);
cSegments = {};

for i=1:nPhoneRecords
    phoneRecord = cPhoneRecords{i};
    cNewSegments = SegmentSynthesizer.segmentPhoneRecord(phoneRecord, segmentLength, sampleRate);
    cSegments = [cSegments; cNewSegments];
end

 cTimeSeries = ...
     SegmentSynthesizer.createSyntheticSegments(cSegments, cSacRecords, ...
     segmentLength, sampleRate, minSeismicAmplitude, scale);


% ------------------------------------------------------------------------

function testSegmentSynthesizerMinAmplitude
% try a non-zero min amplitude
import phone.*
import sac.*
import synthetic.*
import check.*
import timeSeries.*

phoneDir = 'testData/acsnDir';
sacRootDir = 'testData/sacComponents';

cPhoneRecords = PhoneRecord.loadPhoneRecordDir(phoneDir);
cSacRecords = SacLoader.loadSacRecords(sacRootDir);

segmentLength = 2; % seconds
sampleRate = 50; % samples per second
minSeismicAmplitude = 4; % m/s^2
scale = 1;

%

nPhoneRecords = length(cPhoneRecords);
cSegments = {};

for i=1:nPhoneRecords
    phoneRecord = cPhoneRecords{i};
    cNewSegments = SegmentSynthesizer.segmentPhoneRecord(phoneRecord, segmentLength, sampleRate);
    cSegments = [cSegments; cNewSegments];
end

 cTimeSeries = ...
     SegmentSynthesizer.createSyntheticSegments(cSegments, cSacRecords, ...
     segmentLength, sampleRate, minSeismicAmplitude, scale);


% ------------------------------------------------------------------------


function testCreateOnsetSegmentsAlternate

import phone.*
import sac.*
import synthetic.*
import check.*
import timeSeries.*

phoneDir = 'testData/acsnDir';
sacRootDir = 'testData/sacComponents';

cPhoneRecords = PhoneRecord.loadPhoneRecordDir(phoneDir);
cSacRecords = SacLoader.loadSacRecords(sacRootDir);

w1 = 2.5;
w2 = 5;
sampleRate = 50; % samples per second
threshold = 0.3;

%
segmentLength = w1+w2;

nPhoneRecords = length(cPhoneRecords);
cSegments = {};

for i=1:nPhoneRecords
    phoneRecord = cPhoneRecords{i};
    cNewSegments = SegmentSynthesizer.segmentPhoneRecord(phoneRecord, segmentLength, sampleRate);
    cSegments = [cSegments; cNewSegments];
end

cTimeSeries = ...
     SegmentSynthesizer.createOnsetSegmentsAlternate(cSegments, cSacRecords, ...
                w1, w2, threshold, 1, sampleRate); % one is a dummy value

% ------------------------------------------------------------------------
