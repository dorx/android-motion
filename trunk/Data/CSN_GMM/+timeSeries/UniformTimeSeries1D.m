classdef UniformTimeSeries1D < timeSeries.TimeSeries
    % UniformTimeSeries - time series with uniform sampling rate
    %   
    % This is very similar to Matlab's "timeseries". 
    % Note: this is now obsolete, and has been replaced with the
    % (multi-dimensional) UniformTimeSeries
    %
    % author: Matt Faulkner
    %
    properties
        Fs          % sample rate. Positive scalar.
        X           % values. Column vector
        startTime   % start time (seconds)
    end
    
    methods
        
        % ---------------------------------------------------------------
        
        % Constructor.
        %   X - Values. Column vector
        %   Fs - sampling rate (samples per second)
        %   startTime - (optional) time of first data point. Seconds
        %
        function obj = UniformTimeSeries(X, Fs, startTime)
            import check.*
            
            if ~isColumnVector(X)
                error('X must be a column vector')
            end
            
            if ~isPositiveScalar(Fs)
                error('Fs must be a positive scalar')
            end
            
            obj.X = X;
            obj.Fs = Fs;
            
            if nargin <= 2
                obj.startTime = 0;
            else
                if ~isscalar(startTime)
                    error('startTime must be scalar')
                end
                obj.startTime = startTime;
            end
        end
        
        % ---------------------------------------------------------------
        
        function s = lengthSeconds(obj)
            % Output:
            %   s - duration of time series, in seconds.
            %
            % Not sure if this is off by one sample interval (that is, what
            % should be the length of a time series with only one point?)
            %
            assertInstance(obj)
            s = max(obj.getTimes()) - obj.startTime;
            
        end
        
        % ---------------------------------------------------------------
        
        function t = endTime(obj)
            %
            % Now sure how to define a 
            %
            assertInstance(obj);
            t = obj.startTime + obj.lengthSeconds();
        end
        
        % ---------------------------------------------------------------
        
        function T = getTimes(obj)
            % Sample times (seconds)
            %
            % T column vector
            %
            assertInstance(obj)
            n = length(obj.X);
            sampleIndices = 0:(n-1);
            sampleOffsets = sampleIndices / obj.Fs;
            T = sampleOffsets + obj.startTime;
            T = T'; 
        end
        % ---------------------------------------------------------------
        
        % 
        % Input:
        %   Fresample - resampling rate. Positive scalar
        %
        % Output:
        %   v - (column vector) values of resampled time series
        %   t - (column vector) times of resampled values
        %
        function [xResample, tResample] = getResampledValues(obj, fResample)
            assertInstance(obj)
            import check.*
            
            if ~isPositiveScalar(fResample)
                error('fResample must be a positive scalar')
            end
            
            xResample = resample(obj.X, fResample, obj.Fs);
            n = length(xResample);
            tResample = (0:n-1) / fResample;
            tResample = tResample + obj.startTime;
            tResample = tResample'; % transpose
        end
        
        % ---------------------------------------------------------------
        
        function uTS = resample(obj, fResample)
            assertInstance(obj);
            start = obj.startTime;
            
            xResample = obj.getResampledValues(fResample);
            
            uTS = UniformTimeSeries(xResample, fResample, start);
        end
        
        % ---------------------------------------------------------------
        
        function [xInterp, tInterp] = interpolatedValues(obj, times)
            % Obtain the values at the specified times via interpolation.
            % If a time is outside the duration of this time series, the
            % time series will be padded with zeros
            %
            % Input:
            %   obj - UniformTimeSeries
            %   times - column vector. Seconds
            %
            import check.*
            
            assertInstance(obj)
            
            if ~isColumnVector(times)
                error('times must be a column vector')
            end
            
            sampleTimes = obj.getTimes();
            
            beforeTimes = find(times < obj.startTime);
            
            above = find(times >= min(sampleTimes));
            below = find(times <= max(sampleTimes));
            
            insideIndices = intersect( above, below);
            insideTimes = times(insideIndices);
            
            afterTimes = find(times > max(sampleTimes));
            
            % beforeTimes and afterTimes map to zeros.
            % interpolate the inside times
            
            interpVals = interp1(sampleTimes, obj.X, insideTimes);
            beforeVals = zeros(length(beforeTimes),1);
            afterVals = zeros(length(afterTimes),1);
            
            newVals = [beforeVals; interpVals; afterVals];
            
            xInterp = newVals;
            tInterp = times;
            
            
        end
        
        
        % ---------------------------------------------------------------
        
        
        function uTS = add(A, B)
            % Add B to A
            % 
            % Time series are padded with zers, if necessary, and converted
            % to the sampling rate (via linear interpolation) of A
            %
            import timeSeries.*
            assertInstance(A);
            assertInstance(B);
            
            tMin = min(A.startTime, B.startTime);
            tMax = max(A.endTime(), B.endTime());
            
            outputSampleFrequency = A.Fs;
            
            samplePeriod = 1/ outputSampleFrequency;
            
            times = tMin:samplePeriod:tMax;
            
            aInterpVals = A.interpolatedValues(times');
            bInterpVals = B.interpolatedValues(times');
            
            %
            assert(length(aInterpVals) == length(bInterpVals))
            %
            
            vals = aInterpVals + bInterpVals;
            uTS = UniformTimeSeries(vals, outputSampleFrequency, tMin); 

        end
            
        
        % ---------------------------------------------------------------
        
        % shift
        
        % ---------------------------------------------------------------
        
        % scale
        
        % ---------------------------------------------------------------
        
        function assertInstance(obj)
            assert( isa( obj, 'timeSeries.UniformTimeSeries'));
        end
        
        % ---------------------------------------------------------------
    end
    
end

