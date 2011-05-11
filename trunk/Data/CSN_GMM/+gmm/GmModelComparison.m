classdef GmModelComparison
    % GmModelComparison - evaluate the number of Gaussians to use in the
    % mixture model.
    %   
    %
    % author: Mat Faulkner
    %

    
    % ====================================================================
    
    methods(Static)
        
        % ----------------------------------------------------------------
        
        function [bestK, AUC] = ...
                selectMaxAUC(cTrainingFeatures, cTestingFeatures, K)
           % chooses the value of k which maximizes the AUC on (labelled)
           % test data.
           %
           % Input:
           %    cTrainingFeatures - cell array of Feature objects
           %
           %    cTestingFeatures - cell array of Feature objects. These
           %        should have their labels set: 2 is a "normal" or
           %        "negative" data point, and 1 is a "positive" or
           %        "anomaly" data point.
           %
           %    K - column vector of k values (number of Gaussians in
           %        mixture)
           %
           % Output:
           %    bestK - value of k that produced highest LLH
           %    AUC - column vector of AUC values for each k
           %
           import gmm.*
           import check.*
           import feature.*
           import roc.*
           
           if(~isColumnVector(K))
               error('K must be a column vector')
           end
           
           % check that K only contains positive integers
           
           nThresholds = 500; % number of -LLH thresholds for ROC curve
           
           nKValues = length(K);
           AUC = zeros(nKValues,1);
           
           testingLabels = Feature.unpackLabels(cTestingFeatures);
           
           parfor i=1:nKValues
               k = K(i);
               gm = gmm.GaussianMixture.learnGaussianMixture( cTrainingFeatures, k);
               
               P = gm.evaluateProbability(cTestingFeatures);
               
               Assignments = -log(P);
               
               % a low hack to deal with the infinite!
               infIndices = (Assignments == inf);
               Assignments(infIndices) = 1000;
               
               Thresholds = linspace(min(Assignments), max(Assignments), nThresholds);
               
               % sweep thresholds to make an ROC
               [TP, FP] =  myROC( testingLabels, Assignments, Thresholds );
               AUC(i) = auc( FP, TP );
               
               % should save other statistics, like TP and FP
               % would be good to define a class that encapsulates these
               % performance metrics.
           end
           
           [~, I] = max(AUC);
           bestK = K(I);
           
        end
        
        % ----------------------------------------------------------------
        
    end
    
    % ====================================================================
    
end

