function test_suite = testSvmLight
clear all; % to reload class definitions
initTestSuite;
% xUnit test suite. Functions must not end with "end" statement.
%
% author: Matt Faulkner

% ------------------------------------------------------------------------
function testNoParams()
% test that svmLight can be called without crashing. This primarily tests
% that the underlying SVM Light code is properly compiled, on the path,
% etc.
import svm.*
import check.*

% each row is a data point
nTrain = 10; featureLength = 4;
xtrain = rand(nTrain,featureLength);
ytrain = 2*floor( 2*rand(nTrain,1) ) - 1;

nTest = 5;
xtest = rand(nTest, featureLength);

Y = svmlight(xtrain, ytrain, xtest);
assertTrue(isColumnVector(Y))
assertEqual( length(Y), nTest)

% ------------------------------------------------------------------------

function testParams()
import svm.*
import check.*

% each row is a data point
nTrain = 10; featureLength = 4;
xtrain = rand(nTrain,featureLength);
ytrain = 2*floor( 2*rand(nTrain,1) ) - 1;

nTest = 5;
xtest = rand(nTest, featureLength);

params = '-t 2 -g 1 -c 2'; % this should no longer require trailing whitespace

Y = svmlight(xtrain, ytrain, xtest, params);
assertTrue(isColumnVector(Y))
assertEqual( length(Y), nTest)

% ------------------------------------------------------------------------



% ------------------------------------------------------------------------