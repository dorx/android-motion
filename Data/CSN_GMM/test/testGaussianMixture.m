function test_suite = testGaussianMixture
clear all; % to reload class definitions
initTestSuite;
% xUnit test suite. Functions must not end with "end" statement.
%
% author: Matt Faulkner

% ------------------------------------------------------------------------

function testConstructor
% test that it doesn't crash, and try corner cases
import gmm.*
import check.*

Xa = rand(3,20);

gaussianMixtureOneA = GaussianMixture.learnGaussianMixture(Xa,1);  % k=1 
gaussianMixtureTwoA = GaussianMixture.learnGaussianMixture(Xa,2);  % k=2

gaussianMixtureOneA.evaluateProbability(Xa(:,1));
gaussianMixtureTwoA.evaluateProbability(Xa(:,1));

Xb = rand(1,20);

gaussianMixtureOneB = GaussianMixture.learnGaussianMixture(Xb,1);  % k=1 
gaussianMixtureTwoB = GaussianMixture.learnGaussianMixture(Xb,2);  % k=2 

gaussianMixtureOneB.evaluateProbability(Xb(:,1));
gaussianMixtureTwoB.evaluateProbability(Xb(:,1));

Xc = rand(3,1);

gaussianMixtureOneC = GaussianMixture.learnGaussianMixture(Xc,1);  % k=1 
gaussianMixtureTwoC = GaussianMixture.learnGaussianMixture(Xc,2);  % k=2 

gaussianMixtureOneC.evaluateProbability(Xc(:,1));
gaussianMixtureTwoC.evaluateProbability(Xc(:,1));

% ------------------------------------------------------------------------




% ------------------------------------------------------------------------





% ------------------------------------------------------------------------
