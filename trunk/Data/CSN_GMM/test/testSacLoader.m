function test_suite = testSacLoader
clear all; % to reload class definitions
initTestSuite;
% xUnit test suite. Functions must not end with "end" statement.
%
% author: Matt Faulkner

% ------------------------------------------------------------------------

function testLoadSacFile
% load one SAC file without crashing
import sac.*
import check.*

sacFile = 'testData/testSAC.HHZ.sac';

[acceleration, Fs, sacHeader] = SacLoader.loadSacFile(sacFile);

% NOTE: I used loadSacFile to get these values, so these tests are only
% here to alert me in case anything changes
assertEqual(Fs, 100);
assertEqual(length(acceleration), 12118)
assertTrue(isColumnVector(acceleration))


% ------------------------------------------------------------------------

function testLoadSacDir
import sac.*
import check.*

sacDir = 'testData/sacDir';

 [cAccel, cFs, cNames] = SacLoader.loadSacDir(sacDir);
 
 nFiles = 4;
 
 assertEqual(length(cAccel), nFiles)
 assertEqual(length(cFs), nFiles)
 assertEqual(length(cNames), nFiles)
 
 assertEqual(cFs{1}, 100)
 
 assertTrue(isColumnVector(cAccel{1}));

% ------------------------------------------------------------------------

function testLoadSacRecords
import sac.*
import check.isColumnVector

rootDir = 'testData/sacComponents';

cSacRecords = SacLoader.loadSacRecords(rootDir);

nCompleteRecords = 3;

disp('>> A warning here is the correct behavior')
assertEqual(length(cSacRecords), nCompleteRecords)

sacRecord = cSacRecords{1};

% test out the sacRecord. This should be in some unit test of SacRecord...

magnitude = sacRecord.getMagnitude();
assertTrue(isColumnVector(magnitude));

% ------------------------------------------------------------------------