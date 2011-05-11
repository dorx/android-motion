function test_suite = testUniformTimeSeries
clear all; % to reload class definitions
initTestSuite;
% xUnit test suite. Functions must not end with "end" statement.
%
% author: Matt Faulkner


% ------------------------------------------------------------------------

% construct without crashing. 2 arguments
function testConstructor
    import timeSeries.*
    X = ones(1,3);
    Fs = 2;
    
    uTS = UniformTimeSeries(X, Fs);
    
    assertVectorsAlmostEqual(uTS.X, ones(1,3));
    assertEqual(uTS.Fs, Fs)
    assertEqual(uTS.startTime, 0)

        
% ------------------------------------------------------------------------


% construct without crashing. 3 arguments
function testConstructor2
    import timeSeries.*
    X = ones(3,1);
    Fs = 2;
    startTime = 2.5;
    
    uTS = UniformTimeSeries(X, Fs, startTime);
    
    assertVectorsAlmostEqual(uTS.X, ones(3,1));
    assertEqual(uTS.Fs, Fs)
    assertEqual(uTS.startTime, startTime)
    

% ------------------------------------------------------------------------
function testLengthSeconds
import timeSeries.*
X = ones(1,100);
Fs = 2.1;

uTS = UniformTimeSeries(X, Fs);

assertElementsAlmostEqual(uTS.lengthSeconds, 99/2.1, 'absolute', 0.001) % Check here for off-by-one

% ------------------------------------------------------------------------

function testResample
import timeSeries.*
import check.*

n = 100;
X = ones(1,n);
Fs = 2;
startTime = 0;

uTS = UniformTimeSeries(X, Fs, startTime);

resampleRate = 4; % samplesPerSecond

[xResample, tResample] = uTS.getResampledValues(resampleRate);
nResample = length(xResample);

assertEqual(200, nResample)
assertTrue( isRowVector(xResample) );
assertTrue( isColumnVector(tResample) );
disp('TODO: more UniformTimeSeries resample tests')

% ------------------------------------------------------------------------

function testEndTime
%
% Warning: not sure how to define the length of a signal with only one point 
%
import timeSeries.*
import check.*

n = 1;
X = ones(n,1);
Fs = 2;
startTime = -1;

uTS = UniformTimeSeries(X, Fs, startTime);


% ------------------------------------------------------------------------

function testGetTimes
import timeSeries.*
import check.*

n = 4;
X = ones(1,n);
Fs = 2;
startTime = -1;

uTS = UniformTimeSeries(X, Fs, startTime);

expectedTimes = [-1; -0.5; 0; 0.5];

assertVectorsAlmostEqual(uTS.getTimes(), expectedTimes)

% ------------------------------------------------------------------------

function testinterpolatedValues
import timeSeries.*
import check.*

X = [1,2,3,4]; % each column is a data point. Need at least two data points to interpolate
Fs = 2;
startTime = -1;

uTS = UniformTimeSeries(X, Fs, startTime);

times = [-1.5; -1; -0.75; -0.5; 2];
[xResample, tResample] = uTS.interpolatedValues(times);

expectedValues = [0, 1, 1.5, 2, 0];

assertVectorsAlmostEqual(times, tResample);

assertVectorsAlmostEqual(xResample, expectedValues);


% ------------------------------------------------------------------------

function testAdd
import timeSeries.*
import check.*


xA = [1,2,3,4];
FsA = 2;
startTimeA = -1;

A = UniformTimeSeries(xA, FsA, startTimeA);

xB = [5,6,7,8];
FsB = 1;
startTimeB = 3;

B = UniformTimeSeries(xB, FsB, startTimeB);

C = A.add(B);

% t     val
% -1    1
% -0.5  2
% 0     3
% 0.5   4
% 1     0
% 1.5   0
% 2     0
% 2.5   0
% 3     5
% 3.5   5.5
% 4     6
% 4.5   6.5
% 5     7
% 5.5   7.5
% 6     8

expectedTimes = (-1:0.5:6)';
expectedVals = [1,2,3,4,0,0,0,0,5.0,5.5,6,6.5,7,7.5,8];


assertVectorsAlmostEqual(expectedTimes, C.getTimes())
assertVectorsAlmostEqual(expectedVals, C.X)

% ------------------------------------------------------------------------

function testMultiDimensionalConstructor
    import timeSeries.*
    
    nDimensionalData = 4;
    nDataPoints = 10;
    
    % each column is a data point
    X = ones(nDimensionalData, nDataPoints);
    Fs = 2;
    
    uTS = UniformTimeSeries(X, Fs);
    
    assertVectorsAlmostEqual(uTS.X, X);
    assertEqual(uTS.Fs, Fs)
    assertEqual(uTS.startTime, 0)

% ------------------------------------------------------------------------

%function testMultiDimensionalResample


% ------------------------------------------------------------------------

%function testMultiDimensionalInterpolation



% ------------------------------------------------------------------------


function testGetOnset

import timeSeries.*
    
    nDimensionalData = 4;
    nDataPoints = 10;
    
    % each column is a data point
    X = [0,0,0,0,0,0,0,0,0,0,4,4,4,4,0,0,0,0];
    Fs = 2;
    
    w1 = 1; % seconds
    w2 = 3; % seconds
    threshold = 1;
    
    uTS = UniformTimeSeries(X, Fs);
    
    [event, rest] = uTS.getOnset(w1,w2, threshold);
    
    expectedEvent = [0 0 4 4 4 4 0 0];
    expectedRest = [0 0];
    
    assertVectorsAlmostEqual(event.X, expectedEvent)
    assertVectorsAlmostEqual(rest.X, expectedRest)
    
    assertEqual(uTS.Fs, event.Fs)
    assertEqual(uTS.Fs, rest.Fs)
