classdef StaLtaFeature < feature.Feature
    % StaLtaFeature - compute short term average over long term average of
    % frequency coefficients below a cutoff frequency.
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
    % author: Matt Faulkner
    %
    
    
    % ===================================================================
    
    properties
        ratio   % ratio of STA / LTA 
        Fc      % cutoff frequency (Hz)
        tLong   % length of long-term buffer (seconds)
        tShort  % length of short-term bufer
        label
    end
    
    % ===================================================================
    
    methods
        
        % ---------------------------------------------------------------
        function obj = StaLtaFeature(timeSeries, tLong, tShort, Fc, label)
            % constructor
            %
            % Input:
            %    timeSeries - UniformTimeSeries object
            %    tLong - length (seconds) of long-term data
            %    tShort- length (seconds) of short-term data
            %    Fc - cutoff frequency (Hz)
            %    label - (optinal) integer label
            %
            
            import feature.*
            import timeSeries.*
            import check.*
            
            data = timeSeries.X;
            sampleRate = timeSeries.Fs; % (samples per second)
            length = timeSeries.lengthSeconds();
            
            assert(isNonNegativeScalar( tLong ));
            assert(isNonNegativeScalar( tShort ));
            assert(isNonNegativeScalar( Fc ));
            
            if nargin == 4
                label = 0;
            end
            
            if (length < (tLong + tShort))
               disp(['length: ' num2str(length)])
               disp(['tLong: ' num2str(tLong)])
               disp(['tShort: ' num2str(tShort)])
               
               err = MException('StaLtaFeature:InsufficientLength', ...
                   'time Series is not long enough. length: %f, tLong: %f, tShort: %f', length, tLong, tShort);
               throw(err); 
            end
            
            % separate short term and long term data
            
            nLongTermDataPoints = ceil(tLong*sampleRate);
            nShortTermDataPoints = ceil(tShort*sampleRate);
            
            longTermData = data(:,1:nLongTermDataPoints);
            
            shortTermData = data(:, end-nShortTermDataPoints+1:end);

            % FFT
            
            sta = StaLtaFeature.averageFrequencyCoefficient(shortTermData, sampleRate, Fc);
            lta = StaLtaFeature.averageFrequencyCoefficient(longTermData, sampleRate, Fc);
            
            obj.ratio = mean(sta) / mean(lta); % average the X,Y,Z values
            obj.Fc = Fc;
            obj.tLong = tLong;
            obj.tShort = tShort;
            obj.label = label;
            
        end
        
        
        % ----------------------------------------------------------------
       

        % get the length of the feature vector
        function n = length(obj)
            n = 1;
        end
        
        % ---------------------------------------------------------------
        
        % return the feature vector as a column vector
        function v = getFeatureVector(obj)
            v = ratio;
        end
        
        % ---------------------------------------------------------------
        
        % return label of feature. Must be an integer.
        function label = getLabel(obj)
            label = obj.label;
        end
        
        % ---------------------------------------------------------------
        
    end
    
    
    % ====================================================================
        
    
    methods(Static)
         
        function avgCoeff = averageFrequencyCoefficient(x, sampleRate, Fc)
           % averageFrequencyCoefficient - compute the average of FFT
           % coefficients of frequencies at or below the cutoff.
           %
           % Input: 
           %    x - matrix of values. Each column is a data point.
           %    sampleRate - sample rate of x. Samples per second.
           %    Fc - cutoff frequency (Hz)
           %
           % Output:
           %    avgCoeff - column vector of average freq. coefficients, for each
           %        row of x
           %
           import feature.*
           import check.*
           
           [m,n] = size(x);
           
           avgCoeff = zeros(m,1);
           
           T = n / sampleRate; % duration of signal (seconds)
           
           frequencies = [0 : m/2 - 1]/T;
           
           % indices of freqencies <= cutoff
           
           keepIndices = find(frequencies <= Fc);

           for i=1:m
              % FFT of row i
              
              % Matlab's FFT produces complex values, for both positive and
              % negtive frequencies. For real inputs, the values at negative
              % frequencies are the complex conjugate of the positive
              % frequencies. The abs makes them real.
              
              p = abs( fft(x(i,:)) ) /(n/2); % normalized magnitude
              
              % coefficients <= cutoff
              p = p(keepIndices);
              
              avgCoeff(i) = mean(p);
           end
           
        end
        
        % ----------------------------------------------------------------
        
    end
            
    end

