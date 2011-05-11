function test_suite = testPcaFeature
clear all; % to reload class definitions
initTestSuite;
% xUnit test suite. Functions must not end with "end" statement.
%
% author: Matt Faulkner

% ------------------------------------------------------------------------

function testConstructorBasic
%
import feature.*
import timeSeries.*
import phone.*
import synthetic.*

disp('Testing PCA feature')

% load up a time series
acsnFile = 'testData/walk.acsn';
segmentLength = 2;
sampleRate = 50;

% feature parameters
nFreqZ = 8;
nMomZ = 4;
nFreqXY = 8;
nMomXY = 4;
label = 1;


phoneRecord = PhoneRecord(acsnFile);
cTimeSeries = SegmentSynthesizer.segmentPhoneRecord(phoneRecord, segmentLength, sampleRate);

timeSeries = cTimeSeries{1}; % these seem to be only 99 data points, not 100...

xyzFeature = XyzFeature(timeSeries,  nFreqZ, nMomZ, nFreqXY, nMomXY, label);

% could check that the feature vector seems to be what I'd expect by
% computing the FrequencyFeature of each component...

featureLength = xyzFeature.length;
C = eye(featureLength);
mu = zeros(featureLength,1);
sigma = ones(featureLength,1);
k = 5;
label = xyzFeature.label;

pcaFeature = PcaFeature(xyzFeature.featureVector, C, mu, sigma, k, label);