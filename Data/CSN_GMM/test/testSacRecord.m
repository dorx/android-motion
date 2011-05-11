function test_suite = testSacRecord
clear all; % to reload class definitions
initTestSuite;
% xUnit test suite. Functions must not end with "end" statement.
%
% author: Matt Faulkner

% -----------------------------------------------------------------------

% -----------------------------------------------------------------------

function test_scaleToPeakAmplitude
import sac.*

eFileName = 'testData/sacComponents/e/2050647.ZY.EDOM.HHE.sac';
nFileName = 'testData/sacComponents/n/2050647.ZY.EDOM.HHN.sac';
zFileName = 'testData/sacComponents/z/2050647.ZY.EDOM.HHZ.sac';

sacRecord = SacRecord(eFileName, nFileName, zFileName);

originalMagnitude = sacRecord.getMagnitude();
% figure()
% plot(originalMagnitude)
% title('original magnitude')

originalPeak = max(sacRecord.getMagnitude);
disp(['original peak: ' num2str(originalPeak)])

peakAmplitude = max(originalMagnitude); % m/s^2;

sacRecord = sacRecord.scaleToPeakAmplitude(peakAmplitude);
magnitude = sacRecord.getMagnitude();

% figure
% plot(magnitude)
% title('scaled magnitude')

assertElementsAlmostEqual(max(abs(magnitude)), peakAmplitude);

% -----------------------------------------------------------------------