function test_suite = testSacWaveform
clear all; % to reload class definitions
initTestSuite;
% xUnit test suite. Functions must not end with "end" statement.
%
% author: Matt Faulkner

% ------------------------------------------------------------------------

function test_basic
% load a SAC file
%
import sac.*

sacFile = 'testData/sacDir/sacOne.HHZ.sac';
sacWaveform = SacWaveform(sacFile);

% ------------------------------------------------------------------------

function test_scaling
% load a SAC file
%
import sac.*

sacFile = 'testData/sacDir/sacOne.HHZ.sac';
sacWaveform = SacWaveform(sacFile);

peakAmplitude = 10; %m/s^2

sacWaveform = sacWaveform.scaleToPeakAmplitude(peakAmplitude);

acceleration = sacWaveform.accel;

assertEqual(peakAmplitude, max(abs(acceleration)))

% ------------------------------------------------------------------------