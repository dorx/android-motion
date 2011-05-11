classdef UniformTimeSeries < timeSeries.TimeSeries
    % UniformTimeSeries - time series with uniform sampling rate
    %   
    % This is very similar to Matlab's "timeseries".
    %
    % author: Matt Faulkner
    %
    properties
        Fs          % sample rate. Positive scalar.
        X           % matrix of values. Each column is a data point.
        startTime   % start time (seconds)
    end
    
    methods
        
        % ---------------------------------------------------------------
        
        % Constructor.
        %   X - Values. Each column is a data point. (what if X is empty?)
        %   Fs - sampling rate (samples per second)
        %   startTime - (optional) time of first data point. Seconds
        %
        function obj = UniformTimeSeries(X, Fs, startTime)
            import check.*

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
            s = max(obj.getTimes()) - obj.startTime;
            
        end
        
        % ---------------------------------------------------------------
        
        function t = endTime(obj)
            %
            % NOTE: Now sure how to define end time for one sample.
            %
            t = obj.startTime + obj.lengthSeconds();
        end
        
        % ---------------------------------------------------------------
        
        function T = getTimes(obj)
            % Sample times (seconds)
            %
            % T - column vector of sample times. (extrapolated from start
            %   time and sample rate.)
            %
            n = size(obj.X,2);
            sampleIndices = 0:(n-1);
            sampleOffsets = sampleIndices / obj.Fs;
            T = sampleOffsets + obj.startTime;
            T = T'; 
        end
        % ---------------------------------------------------------------
        
        
        function [xResample, tResample] = getResampledValues(obj, fResample)
            %
            % Input:
            %   fResample - resampling rate. Positive scalar
            %
            % Output:
            %   xResample - (matrix) values of resampled time series. Each
            %     column is a data point.
            %   tResample - (column vector) times of resampled values
            %
            import check.*
            
            if ~isPositiveScalar(fResample)
                error('fResample must be a positive scalar')
            end
            
            % 'resample' resamples the columns of its input, so transpose
            % the ceil's are because resample requires positive integers
            % The 100's are there to reduce the effect of rounding error.
            % LOOK HERE FOR A BUG!
            xResample = transpose(resample(transpose(obj.X), ceil(100*fResample), ceil(100*obj.Fs)));
            n = size(xResample,2);
            tResample = (0:n-1) / fResample;
            tResample = tResample + obj.startTime;
            tResample = tResample'; % transpose
        end
        
        % ---------------------------------------------------------------
        
        function uTS = resample(obj, fResample)
            %
            % Input:
            %   fResample - samples per second
            import timeSeries.*
            
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
            % Output:
            %   xInterp - matrix of interpolated values. Each column is a
            %       data point.
            %   tInterp - times of interpolated data. Column vector.
            %
            import check.*
            
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
            
            % interp1 interpolates the columns, so transpose. Not sure how
            % to use interp1 for multi-dimensional arrays. There might also
            % be a bug in M2009B (uses length instead ofsize)
            %
%             interpVals = ...
%                 transpose(interp1(sampleTimes, transpose(obj.X), insideTimes));
            %
            % I'll just interpolate the rows of X explicitly:
            %
            nRowsX = size(obj.X,1);
            nResamplePoints = length(insideTimes);
            
            interpVals = zeros(nRowsX, nResamplePoints);
            
            for i=1:size(obj.X,1)
                % interp1q is the "quicker" interp1
               interpVals(i,:) = transpose(interp1q(sampleTimes, transpose(obj.X(i,:)), insideTimes));
            end
            
            beforeVals = zeros(nRowsX, length(beforeTimes));
            afterVals = zeros(nRowsX, length(afterTimes));
            
            newVals = [beforeVals, interpVals, afterVals];
            
            xInterp = newVals;
            tInterp = times;
            
            assert(isColumnVector(tInterp))
        end
        
        % ---------------------------------------------------------------
%         
%         function uTS = interpolate(obj, times)
%            % same as interpolatedValues, but returns a UniformTimeSeries object. 
%            % 
%            % Input: 
%            %    times - column vector of times (seconds)
%            %
%            import timeSeries.*
%            import check.*
%            
%            assert(isColumnVector(times))
%            
%            [xInterp, tInterp] = interpolatedValues(obj, times);
%            
%            uTS = 
%         end
        
        % ---------------------------------------------------------------
        
        function [x, t] = getInterval(obj, t0, t1)
           % get an interval from t0 to t1, padding with zeros if necessary
           %
           % Input:
           %    t0 - start time, seconds
           %    t1 - end time, seconds
           %    
           % Output:
           %    x - matrix of values. Each column is a data point.
           %    t - times of data. Column vector.
           %
           import timeSeries.*
           import check.*
           
           assert(t0 <= t1)
           assert(isscalar(t0))
           assert(isscalar(t1))
           
           % TODO: a better way (to avoid interpolating) is to extend the
           % sample times periodically as needed to pad with zeros. 
           % 
           % This way is easier, and probably works pretty well...
           %
           secondsPerSample = 1 / obj.Fs;
           
           % times must be a column vector
           times = transpose(t0:secondsPerSample:t1);
           
           [x,t] = obj.interpolatedValues(times);
           
           
           
        end
        
        % ---------------------------------------------------------------
        
        function uTS = interval(obj, t0, t1)
           %
           %
           import timeSeries.*
           import check.*
           
           x = obj.getInterval(t0, t1);
           uTS = UniformTimeSeries(x, obj.Fs, t0);
        end
        
        % ---------------------------------------------------------------
        
        function uTS = add(A, B)
            % Add B to A
            % 
            % Time series are padded with zeros, if necessary, and
            % converted to the sampling rate (via linear interpolation) of
            % A
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
        
        function uTS = scale(obj, scaleFactor)
            import timeSeries.*
            import check.*
            
            if ~isscalar(scaleFactor)
                error('scaleFactor is not a scalar')
            end
            
            scaledX = obj.X * scaleFactor;
            uTS = UniformTimeSeries(scaledX, obj.Fs, obj.startTime);
        end
        
        % ---------------------------------------------------------------
        
        function [event, rest] = getOnset(obj, w1, w2, threshold)
           % detect the first time the signal exceeds a threshold, 
           % and return w1 seconds before and w2 seconds after. The output
           % is padded with zeros if necessary, and may be empty.
           %
           % Input:
           %   w1 - duration (seconds) of data preceding event to return.
           %   w2 - duration (seconds) of data after event to return.
           %   threshold - threshold on absolute amplitude to trigger detection of onset
           %
           % Output:
           %    event - UniformTimeSeries object, if an onset is detected,
           %    otherwise {}.
           %    rest - UniformTimeSeries object, if any of the input is
           %    after the event, otherwise {}.
           %
           import timeSeries.*
           
           % check for an onset
           
           index = find(abs(obj.X) >= threshold, 1);
           
           if isempty(index)
               % no onset detected
               event = {};
               rest = {};
               return;
           end
           
            
            
            % extract the period of time around the onset
            
            % this is kind of dirty...
            secondsPerSample = 1/obj.Fs;
            onsetTime = (index-1) * secondsPerSample;
            
            eventStartTime = onsetTime - w1;
            eventEndTime = onsetTime + w2 - secondsPerSample;
            
            eventData = obj.getInterval(eventStartTime, eventEndTime);
            
            % create a UniformTimeSeries object for the event
            
            event = UniformTimeSeries(eventData, obj.Fs, 0); % what should be used as the initial time?
            
            % and the rest.
            
            if eventEndTime >= obj.endTime
                rest = {};
                return
            else
               restData = obj.getInterval(eventEndTime + secondsPerSample, obj.endTime);
               rest = UniformTimeSeries(restData, obj.Fs, 0); % what should be used as the initial time?
            end
           
            
            
        end
        
        % ---------------------------------------------------------------
        
        function cTimeSeries = segment(obj, segmentLength, sampleRate)
           % segment - divide this into uniform time series objects of the
           % specified duration, and sample rate. This code originally
           % appeared in SegmentSynthesizer.segmentPhoneRecord
           %
           % Input:
           %    segmentLength - seconds
           %    sampleRate - samples per second
           %
           % Output:
           %    cTimeSeries - cell array of uniform time series objects,
           %    possibly empty.
           %
           import timeSeries.*
           import check.*
           
           if ~isNonNegativeScalar(segmentLength)
               error('segmentLength must be a non-negative scalar')
           end
           
           if ~isNonNegativeScalar(sampleRate)
               error('sampleRate must be a non-negative scalar')
           end
           
           if isempty(obj.X)
              cTimeSeries = {};
              return;
           end
           
           % determine number of samples per segment, and number of
           % segments that will be produced.
           
           
           thisSampleRate = obj.Fs; % sample rate of this UniformTimeSeries object
           nThisSamplesPerSegment = ceil(thisSampleRate * segmentLength);
           
           data = obj.X;
           nSamples = size(data,2);
           
           nSegments = floor(nSamples / nThisSamplesPerSegment);
           
           %
           if nSegments == 0
              % length is less than segmentLength. Pad with zeros.
              uTSResample = obj.resample(sampleRate);
              
              timeSeries = uTSResample.interval(0, segmentLength);
              
              cTimeSeries = cell(1,1);
              cTimeSeries{1} = timeSeries;
              return
           end
           %
           
           nThisSamplesUsed = nSegments * nThisSamplesPerSegment;
           
           x = data(1,1:nThisSamplesUsed);
           y = data(2,1:nThisSamplesUsed);
           z = data(3,1:nThisSamplesUsed);
           
           % reshape so that each row corresponds to one segment
           xSegments = reshape(x, nSegments, nThisSamplesPerSegment);
           ySegments = reshape(y, nSegments, nThisSamplesPerSegment);
           zSegments = reshape(z, nSegments, nThisSamplesPerSegment);
           
           cTimeSeries = cell(nSegments,1);
           parfor i=1:nSegments
              
              dataSegment = zeros(3,nThisSamplesPerSegment);
              dataSegment(1,:) = xSegments(i,:); 
              dataSegment(2,:) = ySegments(i,:); 
              dataSegment(3,:) = zSegments(i,:); 
              
              uTS = UniformTimeSeries(dataSegment, thisSampleRate);
              % TODO: might want to use interpolation at times specified by
              % the desired sample rate and segment length. This resampling
              % appears to produce off-by-one problems. For example a 2
              % second segment at 50 samples per second leads to 99 sample
              % points.
              %
              uTSResample = uTS.resample(sampleRate);
              cTimeSeries{i} = uTSResample;
           end
        end
        
        % ---------------------------------------------------------------
        
        function assertInstance(obj)
            assert( isa( obj, 'timeSeries.UniformTimeSeries'));
        end
        
        % ---------------------------------------------------------------
    end
    
end

