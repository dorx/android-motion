function test_suite = testFrequencyFeature
clear all; % to reload class definitions
initTestSuite;
% xUnit test suite. Functions must not end with "end" statement.
%
% author: Matt Faulkner

% ------------------------------------------------------------------------

% construct without crashing.
function testConstructor
    import feature.*
    
    N = 100;
    X = rand(N,1);
    
    nFrequencyTerms = 10;
    nMoments = 4;
    
    feature = FrequencyFeature(X, nFrequencyTerms, nMoments);
    
    expectedFeatureLength = 15;
    
    assertEqual(feature.nFrequencyTerms, 10)
    assertEqual(feature.length, expectedFeatureLength);
    assertEqual(feature.nMoments, 4);
%     assertVectorsAlmostEqual(uTS.X, ones(3,1));
%     assertEqual(uTS.Fs, Fs)
%     assertEqual(uTS.startTime, 0)

        
% ------------------------------------------------------------------------

function testFeatureFreqTerms
disp('TODO: test for correct FFT terms')

% ------------------------------------------------------------------------
function testMomentTerms
disp('TODO: test for correct moments')

% ------------------------------------------------------------------------
function testFeatureVector
import feature.*
import check.*
    
    N = 100;
    X = rand(N,1);
    
    nFrequencyTerms = 10;
    nMoments = 4;
    
    feature = FrequencyFeature(X, nFrequencyTerms, nMoments);
    v = feature.getFeatureVector();
    assertTrue(isColumnVector(v))

    
% ------------------------------------------------------------------------

function testFeaturize
import feature.*
import check.*
    
    dataLength = 100;
    nData = 8;
    
    X = rand(dataLength,nData);
    
    nFrequencyTerms = 10;
    nMoments = 4;
    
    L = ones(nData,1);

    V = FrequencyFeature.featurize(X, nFrequencyTerms, nMoments, L);
    [m,n] = size(V);
    assertEqual(m, nFrequencyTerms+nMoments+1);
    assertEqual(n, nData)

% ------------------------------------------------------------------------

% ------------------------------------------------------------------------

% ------------------------------------------------------------------------