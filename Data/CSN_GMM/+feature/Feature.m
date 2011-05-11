classdef Feature
    % Feature - interface (abstract class)
    %   
    %
    % author: Matt Faulkner
    %
    
    % ===================================================================
    
    methods (Abstract)
        % retrun the length of the feature vector
        n = length(obj)
        
        % return the feature vector as a column vector
        v = getFeatureVector(obj)
        
        % return label of feature. Must be an integer.
        label = getLabel(obj)
    end
    
    % ====================================================================
    
    methods(Static)
        
        % ----------------------------------------------------------------
        
        function X = unpackFeatureVectors(cFeatures)
            % unpackFeatureVectors - get feature vectors from a cell array
            % of Features
            %
            % Input:
            %    cFeatures - cell array of Feature objects
            %
            % Output:
            %    X - matrix of feature vectors. Each column is a data point
            %
            import feature.*
            
            assert(iscell(cFeatures))
            
            if isempty(cFeatures)
                X = [];
                return
            end
            
            nFeatures = length(cFeatures);
            featureLength = cFeatures{1}.length();
            
            X = zeros(featureLength, nFeatures);
            for i=1:nFeatures
                f = cFeatures{i};
                X(:,i) = f.featureVector;
            end
            
        end
        
        % ----------------------------------------------------------------
        
        function L = unpackLabels(cFeatures)
           % unpackFeatureLabels - get labels from cell array of features
           %
           % Input: 
           %    Features - cell array of Feature objects
           %    
           % Output:
           %    L - column vector of integer labels
           %
           assert(iscell(cFeatures))
            
            if isempty(cFeatures)
                L = [];
                return
            end
            
            nFeatures = length(cFeatures);
            
            L = zeros(nFeatures,1);
            for i=1:nFeatures
                feature = cFeatures{i};
                L(i) = feature.getLabel();
            end
            
            % This doesn't do what I intend
            %if ~isinteger(L)
                %warning('L failed isinteger');
                %disp(L)
            %end
           
        end
        
        % ----------------------------------------------------------------
        
    end
    
    % ====================================================================
    
end

