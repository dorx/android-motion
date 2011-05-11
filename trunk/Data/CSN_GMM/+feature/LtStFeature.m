classdef LtStFeature < feature.Feature
    % StLtFeature - Short-term, long-term feature
    %
    % time series:
    % start |-----------------|------|-------------| end
    %            long term      dead    short term
    %
    % The first tLong seconds of the timeSeries become the long-term data.
    % The last tShort seconds of the timeSeries become the short-term data.
    % Anything left over (in between) becomes "dead" and is not used in the
    % feature calculation.
    %
    %
    % author: Matt Faulkner
    %
    
    % ===================================================================
    
    properties
        featureVector % column vector
        shortTermFeature
        longTermFeature
        label
    end
    
    % ===================================================================
    
    methods
        
        % ---------------------------------------------------------------
        
        function obj = ...
                LtStFeature(timeSeries, tLong, nFLong, nMLong, tShort, nFShort, nMShort, label)
           % constructor
           %
           % Input:
           %    timeSeries - UniformTimeSeries object
           %    tLong - length (seconds) of long-term data
           %    nFLong - number of frequency terms for long-term feature.
           %    nMLong - number of moment terms for long-term feature.
           %    tShort- length (seconds) of short-term data
           %    nFShort- number of frequency terms for short-term feature.
           %    nMShort - number of moment terms for short-term feature.
           %    label - (optinal) integer label
           %
           import feature.*
           import check.*
           import timeSeries.*
           
           data = timeSeries.X;
           sampleRate = timeSeries.Fs;
           length = timeSeries.lengthSeconds();
           
           
           assert(isNonNegativeScalar( tLong ), 'LtStFeature: tLong assert');
           assert(isNonNegativeScalar( nFLong ), 'LtStFeature: nFLong assert');
           assert(isNonNegativeScalar( nMLong ), 'LtStFeature: nMLong assert');
           assert(isNonNegativeScalar( tShort ), 'LtStFeature: tShort assert');
           assert(isNonNegativeScalar( nFShort ), 'LtStFeature: nFLong assert');
           assert(isNonNegativeScalar( nMShort ), 'LtStFeature: nMLong assert');
           
           if nargin == 7
               label = 0;
           end
           
           if (length < (tLong + tShort))
               disp(['length: ' num2str(length)])
               disp(['tLong: ' num2str(tLong)])
               disp(['tShort: ' num2str(tShort)])
               %error('timeSeries is not long enough');
               
               err = MException('LtStFeature:InsufficientLength', ...
                   'time Series is not long enough. length: %f, tLong: %f, tShort: %f', length, tLong, tShort);
               throw(err); 
           end
           
           nLongTermDataPoints = ceil(tLong*sampleRate);
           nShortTermDataPoints = ceil(tShort*sampleRate);
           
           longTermData = data(:,1:nLongTermDataPoints);
           longTermTimeSeries = UniformTimeSeries(longTermData, sampleRate);
           
           shortTermData = data(:, end-nShortTermDataPoints+1:end);
           shortTermTimeSeries = UniformTimeSeries(shortTermData, sampleRate);
           
           obj.longTermFeature = XyzFeature(longTermTimeSeries, nFLong, nMLong);
           obj.shortTermFeature = XyzFeature(shortTermTimeSeries, nFShort, nMShort);
           obj.featureVector = ...
               [obj.longTermFeature.featureVector ; obj.shortTermFeature.featureVector];
           obj.label = label;
           
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
        
        % ---------------------------------------------------------------
        
    end
    
    % ===================================================================
    
end

