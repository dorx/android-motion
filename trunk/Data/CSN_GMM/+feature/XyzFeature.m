classdef XyzFeature < feature.Feature
    % XyzFeature - Feature for phone data that uses the L2 norm of the X and
    % Y acceleration as well as Z, to create a rotationally invariant
    % feature.
    %  
    % author: Matt Faulkner
    %
    
    % TODO: static method to batch create features from a cell array of
    % timeSeries objects.
    %
    
    % ===================================================================    
    
    properties
        featureVector % column vector. Concatenates xy feature, then z feature
        nFrequencyZ
        nMomentsZ
        nFrequencyXY
        nMomentsXY
        label
    end

    
    % ===================================================================    
    
     methods
        
        % ---------------------------------------------------------------
        
        function obj = XyzFeature(timeSeries,  nFreqZ, nMomZ, nFreqXY, nMomXY, label)
            % constructor
            %
            % Input:
            %   timeSeries - UniformTimeSeries object
            %   nFreqZ - number of frequency terms for Z
            %   nMomZ - number of moment terms for Z
            %   nFreqXY - (optional) number of frequency terms for XY 
            %   nMomXY - (optional) number of moment terms for XY
            %   label - (optional) integer label
            import feature.*
            import timeSeries.*
            import check.*
            
            assert(isNonNegativeScalar(nFreqZ));
            assert(isNonNegativeScalar(nMomZ));
            
            if nargin == 3
               % supply optional arguments:
               nFreqXY = nFreqZ;
               nMomXY = nMomZ;
               label = 0;
            end
            
            if nargin == 5
                label = 0;
            end
            
            obj.nFrequencyZ = nFreqZ;
            obj.nMomentsZ = nMomZ;
            obj.nFrequencyXY = nFreqXY;
            obj.nMomentsXY = nMomXY;
            obj.label = label;
            
            data = timeSeries.X;
            
            xy = data(1:2,:);
            
            % compute the L2 norm of each column (data point)
            % The abs isn't necessary for real data.
            % The one explicitly specifies that the columns should be
            % summed. This is an issue if there's only one row (Matlab will
            % then sum the row).
            xyNorm = sqrt(sum(abs(xy).^2,1));
            xyNormFeature = FrequencyFeature(xyNorm', nFreqXY, nMomXY);
            
            z = data(3,:);
            zFeature = FrequencyFeature(z', nFreqZ, nMomZ);
            
            % concatenate column vectors
            obj.featureVector = ...
                [xyNormFeature.featureVector ; zFeature.featureVector];
        end
        
        % ---------------------------------------------------------------
        
        % get the length of the feature vector
        function n = length(obj)
            n = length(obj.featureVector);
        end
        
        % ---------------------------------------------------------------
        
        % return the feature vector as a column vector
        function v = getFeatureVector(obj)
            v = obj.featureVector;
        end
        
        % ---------------------------------------------------------------
        
        % return label of feature. Must be an integer.
        function label = getLabel(obj)
            label = obj.label;
        end
        
    end
    
    % ===================================================================

end

