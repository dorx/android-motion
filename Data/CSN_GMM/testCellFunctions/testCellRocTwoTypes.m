function test_suite = testCellRocTwoTypes
clear all; % to reload class definitions
initTestSuite;
% xUnit test suite. Functions must not end with "end" statement.
%
% author: Matt Faulkner

% ------------------------------------------------------------------------

function testOne

import aggregate.*
% test for one sensor, no fault rates

nA = 1;
nB = 0;

tpA = 0.8;
fpA = 0.1;

tpB = 0.9;
fpB = 0.13;

N = [nA;nB];

TP = [tpA; tpB];
FP = [fpA; fpB];

FaultRates = [0;0];

[ tpr, fpr, thresholds ] = cellRocTwoTypes(N, TP, FP, FaultRates);
[fpr, I] = sort(fpr);
tpr = tpr(I);
clear I;

expectedTpr = [0; 0.8];
expectedFpr = [0; 0.1];

assertVectorsAlmostEqual(tpr, expectedTpr);
assertVectorsAlmostEqual(fpr, expectedFpr);


% ------------------------------------------------------------------------

function testTwo
% test for one sensor, non-zero fault rates.

import aggregate.*

nA = 1;
nB = 0;

tpA = 0.8;
fpA = 0.1;

tpB = 0.9;
fpB = 0.13;

N = [nA;nB];

TP = [tpA; tpB];
FP = [fpA; fpB];

FaultRates = [0.1;0];

% test default FaultRate value
[ tpr, fpr, thresholds ] = cellRocTwoTypes(N, TP, FP, FaultRates);
[fpr, I] = sort(fpr);
tpr = tpr(I);
clear I;

expectedTpr = [0; 0.77];
expectedFpr = [0; 0.14];

assertVectorsAlmostEqual(tpr, expectedTpr);
assertVectorsAlmostEqual(fpr, expectedFpr);


% ------------------------------------------------------------------------
function testThree
import aggregate.*
% test for two sensors, no fault rates

nA = 1;
nB = 1;

tpA = 0.8;
fpA = 0.1;

tpB = 0.9;
fpB = 0.05;

N = [nA;nB];

TP = [tpA; tpB];
FP = [fpA; fpB];

FaultRates = [0;0];

[ tpr, fpr, thresholds ] = cellRocTwoTypes(N, TP, FP, FaultRates);
[fpr, I] = sort(fpr);
tpr = tpr(I);
clear I;

pEvent(1) = 0.2 * 0.1;      % (0,0 | event)
pEvent(2) = 0.8 * 0.1;      % (1,0 | event)
pEvent(3) = 0.2 * 0.9;      % (0,1 | event) 
pEvent(4) = 0.8 * 0.9;      % (1,1 | event)

%
% (0,0 | no ev) = 0.9 * 0.95
% (1,0 | no ev) = 0.1 * 0.95
% (0,1 | no ev) = 0.9 * 0.05
% (1,1 | no ev) = 0.1 * 0.05

% ratios:
expectedThresholds(1) = 0.2*0.1 / (0.9 * 0.95);
expectedThresholds(2) = 0.8 * 0.1 / (0.1 * 0.95);
expectedThresholds(3) = 0.2 * 0.9 / (0.9 * 0.05);
expectedThresholds(4) = 0.8 * 0.9 / (0.1 * 0.05);

assertVectorsAlmostEqual(thresholds, expectedThresholds');

% TODO:
%expectedTpr = [0; 0.8];
%expectedFpr = [0; 0.1];

figure()
plot(fpr, tpr)

%assertVectorsAlmostEqual(tpr, expectedTpr);
%assertVectorsAlmostEqual(fpr, expectedFpr);



% ------------------------------------------------------------------------

function testFour
import aggregate.*
% test two sensors, for various fault rates

nA = 1;
nB = 1;

tpA = 0.8;
fpA = 0.1;

tpB = 0.9;
fpB = 0.13;

N = [nA;nB];

TP = [tpA; tpB];
FP = [fpA; fpB];

[ tprOne, fprOne] = cellRocTwoTypes(N, TP, FP, [0;0]);
[fprOne, I] = sort(fprOne);
tprOne = tprOne(I);
clear I;

[ tprTwo, fprTwo ] = cellRocTwoTypes(N, TP, FP, [0.2, 0]);
[fprTwo, I] = sort(fprTwo);
tprTwo = tprTwo(I);
clear I;

[ tprThree, fprThree ] = cellRocTwoTypes(N, TP, FP, [0.2, 0.2]);
[fprThree, I] = sort(fprThree);
tprThree = tprThree(I);
clear I;

figure()
plot(fprOne, tprOne, fprTwo, tprTwo, fprThree, tprThree)
legend('0,0','0.2,0','0.2,0.2', 'Location', 'SouthEast')
