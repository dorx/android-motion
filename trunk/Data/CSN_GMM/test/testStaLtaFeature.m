function test_suite = testStaLtaFeature
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

disp('Test StaLtaFeature')

% load up a time series
acsnFile = 'testData/walk.acsn';
sampleRate = 50;

% feature parameters
tLong = 10;
tShort = 2;
Fc = 10; % Hz
label = 1;

segmentLength = tLong + tShort;

phoneRecord = PhoneRecord(acsnFile);
%recordLength = phoneRecord.getLength();
%disp(['record length: ' num2str(recordLength)])

cTimeSeries = SegmentSynthesizer.segmentPhoneRecord(phoneRecord, segmentLength, sampleRate);

timeSeries = cTimeSeries{1}; 

staLtaFeature = StaLtaFeature(timeSeries, tLong, tShort, Fc, label);