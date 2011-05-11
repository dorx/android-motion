function test_suite = testLtStFeature
clear all; % to reload class definitions
initTestSuite;
% xUnit test suite. Functions must not end with "end" statement.
%
% author: Matt Faulkner


function testConstructorBasic
%
import feature.*
import timeSeries.*
import phone.*
import synthetic.*

% load up a time series
acsnFile = 'testData/walk.acsn';
sampleRate = 50;

% feature parameters
tLong = 10;
nFLong = 5;
nMLong = 5;
tShort = 2;
nFShort = 5;
nMShort = 5;
label = 1;

segmentLength = tLong + tShort;

phoneRecord = PhoneRecord(acsnFile);
%recordLength = phoneRecord.getLength();
%disp(['record length: ' num2str(recordLength)])

cTimeSeries = SegmentSynthesizer.segmentPhoneRecord(phoneRecord, segmentLength, sampleRate);

timeSeries = cTimeSeries{1}; 

ltStFeature = LtStFeature(timeSeries, tLong, nFLong, nMLong, tShort, nFShort, nMShort, label);

% could check that the feature vector seems to be what I'd expect by
% computing the FrequencyFeature of each component...


