classdef SegmentSynthesizer
    % SegmentSynthesizer - add seismic data to phone data.
    %   
    % TODO: would be better to add the L2 norms of the phone's x and y data
    % with the sac files n and e data, rather than 
    %
    % author: Matt Faulkner
    %
    
    % ====================================================================
    
%     properties(Constant)
%         
%         DISPLAY_WARNINGS = false;
%         
%     end
    
    % ====================================================================
    
    methods(Static)
        
        function cSyntheticSegments= ...
                createSyntheticSegments(cPhoneSegments, cSacRecords, ...
                segmentLength, sampleRate, threshold, peakAmplitude)
            %
            % Identifies SAC segments of sufficient amplitude, scales them,
            % and adds them to segments of phone data
            %
            % Input:
            %    cPhoneSegments 
            %    cSacRecords - cell array of SacRecord objects.
            %    segmentLength - duration (seconds) of output time series.
            %    sampleRate - samples per second of output time series.
            %    threshold - threshold (after scaling) to detect
            %       a seismic event m/s^2
            %    peakAmplitude - seismic events are scaled to have this
            %        peak amplitude
            %   !!! peakAmplitude might be ignored !!!
            %
            % Output:
            %    cSyntheticSegments - cell array of UniformTimeSeries objects. Each
            %        time series is a segment of phone data, with a (scaled)
            %        segment of seismic data. Each column of a time series
            %        is a data point. The first row is the Z dimension, the
            %        second row is the L2 norm of the X and Y (E and N)
            %
            import synthetic.*
            
            assert(nargin == 6, 'createSyntheticSegments: insufficient arguments.')
            
            cSyntheticSegments = ...
                SegmentSynthesizer.createOnsetSegments(cPhoneSegments, cSacRecords, ...
                0, segmentLength, threshold, peakAmplitude, sampleRate);
           
        end
 
        % ---------------------------------------------------------------
        
        function cSyntheticSegments= ...
                createOnsetSegments(cPhoneSegments, cSacRecords, ...
                w1, w2, threshold, peakAmplitude, sampleRate)
            %
            % createOnsetSegments - extract the initial impulse of an
            % earthquake, scale it, and merge it with phone data.
            %
            % Input:
            %   cPhoneSegments (was cPhoneRecords - cell array of
            %   PhoneRecord objects.)
            %   cSacRecords - cell array of SacRecord objects
            %   w1 - duration (seconds) of data preceding event to return.
            %   w2 - duration (seconds) of data after event to return.
            %   threshold - threshold on absolute amplitude to trigger
            %   detection of onset. m/s^2.
            %   peakAmplitude - SAC acceeration will be scaled to have this
            %       amplitude. m/s^2. Scalar 
            %   !!! peakAmplitude might be ignored !!!
            %   sampleRate - phone and seismic data will be resampled to
            %       this rate.
            %
            % Output: 
            %   cSyntheticSegments - cell array of UniformTimeSeries
            %   objects.
            %
            %
            %                        |
            %  ______________________|________________threshold
            %                        |   |
            %            .          .| |||
            %  .     . .  . .      . ||||||. . .
            % - - - - - - - - - - - - - - - - - - - -  0
            %     .             .    ||||||.   .  .
            %                         ||||
            %                          | ||
            %                          | |
            %                          |
            %
            %                       ^
            %                       |
            %                     onset
            %            |----------|------------|
            %                   w1        w2
            %
            import synthetic.*
            import phone.*
            import sac.*
            import timeSeries.*
            import check.*
            
            assert(nargin == 7, 'createOnsetSegments: insufficient arguments')
            
            if ~isNonNegativeScalar(w1)
                error('w1 must be a non-negative scalar')
            end
            
            if ~isNonNegativeScalar(w2)
                error('w2 must be a non-negative scalar')
            end
            
            if ~isNonNegativeScalar(sampleRate)
                error('sampleRate must be a non-negative scalar')
            end
            
            %
            
            
            
            if isempty(cPhoneSegments)
                error('No phone data.')
            end
           
            
            % TODO: the following could be parallelized.
            %
            % identify seismic onsets (and scale)
            
            nSacRecords = length(cSacRecords);
            cSacSegments = {};
            
            for i=1:nSacRecords
                sacRecord = cSacRecords{i};
                
                % LOOK HERE!
                % I turned off the scaling
                %
                %sacRecord = sacRecord.scaleToPeakAmplitude(peakAmplitude);
                
                dataE = sacRecord.eWaveform.accel; %column vector
                dataN = sacRecord.nWaveform.accel; %column vector
                dataZ = sacRecord.zWaveform.accel; %column vector
                
                nSacSamples = length(dataE);
                if (length(dataN) ~= nSacSamples) || (length(dataZ) ~= nSacSamples)
                    %warning('SAC data channels have mismatched lengths. Skipping.')
                    continue
                end

                
                %Note: this can be empty if no onset is detected
                newSacSegment = SegmentSynthesizer.getSacOnsetSegment(sacRecord, w1, w2, threshold);
                
                if ~isempty(newSacSegment)
                    cSacSegments = [cSacSegments ; newSacSegment];
                end
            end
            
            % detect emptys
            
            % combine
            
            if isempty(cSacSegments) 
              warning('No SAC data was accepted.')
              cSyntheticSegments = cPhoneSegments;
              return
            else
                disp([num2str(length(cSacSegments)) 'onset segments extracted.'])
            end
            
            % randomly assign a SAC segment to each phone segment, and add
            % them:
            nSacSegments = length(cSacSegments);
            nPhoneSegments = length(cPhoneSegments);
            
            sacIndices = ceil(nSacSegments * rand(nPhoneSegments,1));
            
            cSyntheticSegments = cell(nPhoneSegments,1);
            
            parfor i=1:nPhoneSegments
                sacIndex = sacIndices(i);
                sacSegment = cSacSegments(sacIndex);
                phoneSegment = cPhoneSegments{i};
                %
                % NOTE: adds x+e, y+n, z+z
                % Might want to add the L2 norm of x,y to the L2 norm of n,e
                %
                syntheticSegment = phoneSegment.add(sacSegment);
                cSyntheticSegments{i} = syntheticSegment;
            end
                        
        end
        
        % ---------------------------------------------------------------
        
        function cSyntheticSegments= ...
                createOnsetSegmentsAlternate(cPhoneSegments, cSacRecords, ...
                w1, w2, threshold, ~, sampleRate)
            %
            % createOnsetSegments - extract the initial impulse of an
            % earthquake, scale it, and merge it with phone data.
            %
            % --> Creates one synthetic segment for each SAC onset, rather 
            %     than one synthetic segment for each phone segment.
            %
            % Input:
            %   cPhoneSegments (was cPhoneRecords - cell array of
            %   PhoneRecord objects.)
            %   cSacRecords - cell array of SacRecord objects
            %   w1 - duration (seconds) of data preceding event to return.
            %   w2 - duration (seconds) of data after event to return.
            %   threshold - threshold on absolute amplitude to trigger
            %   detection of onset. m/s^2.
            %   peakAMlitude - SAC acceeration will be scaled to have this
            %   amplitude. m/s^2. Scalar
            %   sampleRate - phone and seismic data will be resampled to
            %       this rate.
            %
            % Output: 
            %   cSyntheticSegments - cell array of UniformTimeSeries
            %   objects.
            %
            %
            %                        |
            %  ______________________|________________threshold
            %                        |   |
            %            .          .| |||
            %  .     . .  . .      . ||||||. . .
            % - - - - - - - - - - - - - - - - - - - -  0
            %     .             .    ||||||.   .  .
            %                         ||||
            %                          | ||
            %                          | |
            %                          |
            %
            %                       ^
            %                       |
            %                     onset
            %            |----------|------------|
            %                   w1        w2
            %
            import synthetic.*
            import phone.*
            import sac.*
            import timeSeries.*
            import check.*
            import cell.*
            
            assert(nargin == 7)
            
                 
            if isempty(cPhoneSegments)
                error('No phone data.')
            end
           
            % identify seismic onsets
            
            nSacRecords = length(cSacRecords);
            cSacSegments = cell(nSacRecords,1);
            
            parfor i=1:nSacRecords
                sacRecord = cSacRecords{i};
                
                % LOOK HERE!
                % I turned off the scaling
                %
                %sacRecord = sacRecord.scaleToPeakAmplitude(peakAmplitude);
                
                dataE = sacRecord.eWaveform.accel; %column vector
                dataN = sacRecord.nWaveform.accel; %column vector
                dataZ = sacRecord.zWaveform.accel; %column vector
                
                nSacSamples = length(dataE);
                if (length(dataN) ~= nSacSamples) || (length(dataZ) ~= nSacSamples)
                    %warning('SAC data channels have mismatched lengths. Skipping.')
                    continue
                end
                
                %Note: this can be empty if no onset is detected
                cSacSegments{i} = SegmentSynthesizer.getSacOnsetSegment(sacRecord, w1, w2, threshold);
                
            end
            
            cSacSegments = deleteEmptyCells(cSacSegments);
            
            if isempty(cSacSegments) 
              warning('No SAC data was accepted.')
              cSyntheticSegments = {};
              return
            end
            
            % randomly assign a SAC segment to each phone segment, and add
            % them:
            nSacSegments = length(cSacSegments);
            nPhoneSegments = length(cPhoneSegments);
            
            cSyntheticSegments = cell(nSacSegments,1);
            
            phoneIndices = ceil(nPhoneSegments * rand(nSacSegments,1));
            
            cPhoneSegments = cPhoneSegments(phoneIndices);
            
            parfor i=1:nSacSegments
                phoneSegment = cPhoneSegments{i};
                
                if isempty(phoneSegment)
                    disp(num2str(phoneIndex))
                    error('empty phone segment')
                end
                    
                sacSegment = cSacSegments{i};
                cSyntheticSegments{i} = phoneSegment.add(sacSegment);
            end
            
        end
        
        % ---------------------------------------------------------------
        
        function cTimeSeries = ...
                segmentPhoneRecord(phoneRecord, segmentLength, sampleRate)
           %
           % Input:
           %    phoneRecord
           %    segmentLength - seconds (scalar). If the record is not long
           %        enough it will be padded with trailing zeros.
           %    sampleRate - samples per second (scalar)
           %
           % Output:
           %    cTimeSeries - cell array of UniformTimeSeries objects
           %
           import synthetic.*
           import phone.*
           import timeSeries.*
           import check.*
           
           if ~isNonNegativeScalar(segmentLength)
               error('segmentLength must be a non-negative scalar')
           end
           
           if ~isNonNegativeScalar(sampleRate)
               error('sampleRate must be a non-negative scalar')
           end
           
           if isempty(phoneRecord.data)
              cTimeSeries = {};
              return;
           end
           
           % determine number of samples per segment, and number of
           % segments that will be produced.
           
           phoneSampleRate = phoneRecord.sampleRate;
           nPhoneSamplesPerSegment = ceil(phoneSampleRate * segmentLength);
           
           data = phoneRecord.data(1:3,:); % get X,Y,Z
           nPhoneSamples = size(data,2);
           
           nSegments = floor(nPhoneSamples / nPhoneSamplesPerSegment);
           
           %
           if nSegments == 0
              % phoneRecord length is less than segmentLength. Pad with zeros.
              uTS = UniformTimeSeries(data, phoneSampleRate);
              uTSResample = uTS.resample(sampleRate);
              
              timeSeries = uTSResample.interval(0, segmentLength);
              
              cTimeSeries = cell(1,1);
              cTimeSeries{1} = timeSeries;
              return
           end
           %
           
           nPhoneSamplesUsed = nSegments * nPhoneSamplesPerSegment;
           
           x = data(1,1:nPhoneSamplesUsed);
           y = data(2,1:nPhoneSamplesUsed);
           z = data(3,1:nPhoneSamplesUsed);
           
           % reshape so that each row corresponds to one segment
           xSegments = reshape(x, nSegments, nPhoneSamplesPerSegment);
           ySegments = reshape(y, nSegments, nPhoneSamplesPerSegment);
           zSegments = reshape(z, nSegments, nPhoneSamplesPerSegment);
           
           cTimeSeries = cell(nSegments,1);
           parfor i=1:nSegments
              
              dataSegment = zeros(3,nPhoneSamplesPerSegment);
              dataSegment(1,:) = xSegments(i,:); 
              dataSegment(2,:) = ySegments(i,:); 
              dataSegment(3,:) = zSegments(i,:); 
              
              uTS = UniformTimeSeries(dataSegment, phoneSampleRate);
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
        
        function cTimeSeries = ...
                segmentSacRecord(sacRecord, segmentLength, sampleRate)
            %
            % Input:
            %    sacRecord
            %    segmentLength - seconds (scalar)
            %    sampleRate - samples per second (scalar)
            %
            % Output:
            %   cTimeSeries - cell array of UniformTimeSeries containing
            %   consecutive segments of sac time series data
            %
            import synthetic.*
            import phone.*
            import timeSeries.*
            import check.*
            
            if ~isNonNegativeScalar(segmentLength)
                error('segmentLength must be a non-negative scalar')
            end
            
            if ~isNonNegativeScalar(sampleRate)
                error('sampleRate must be a non-negative scalar')
            end
            
            % determine number of samples per segment, and number of
            % segments that will be produced.
            
            % this assumes all e,n,z channels have same sample rate.
            sacSampleRate = sacRecord.eWaveform.sampleRate;
            nSacSamplesPerSegment = ceil(sacSampleRate * segmentLength);
            
            
            dataE = sacRecord.eWaveform.accel; %column vector
            dataN = sacRecord.nWaveform.accel; %column vector
            dataZ = sacRecord.zWaveform.accel; %column vector
            
            nSacSamples = length(dataE);
            if (length(dataN) ~= nSacSamples) || (length(dataZ) ~= nSacSamples)
                cTimeSeries = {};
                %warning('SAC data channels have mismatched lengths. Skipping.')
                return
            end
            
            % truncate the data to be an integer multiple of the number of
            % samples per segment
            
            nSegments = floor(nSacSamples / nSacSamplesPerSegment);
            
            nSacSamplesUsed = nSegments * nSacSamplesPerSegment;
            
            dataE = dataE(1:nSacSamplesUsed,1);
            dataN = dataN(1:nSacSamplesUsed,1);
            dataZ = dataZ(1:nSacSamplesUsed,1);
            
            % reshape so that each row corresponds to one segment
            segmentsE = reshape(dataE, nSegments, nSacSamplesPerSegment);
            segmentsN = reshape(dataN, nSegments, nSacSamplesPerSegment);
            segmentsZ = reshape(dataZ, nSegments, nSacSamplesPerSegment);
            
            cTimeSeries = cell(nSegments,1);
            for i=1:nSegments
                segmentE = segmentsE(i,:);
                segmentN = segmentsN(i,:);
                segmentZ = segmentsZ(i,:);
                
                dataSegment = zeros(3,nSacSamplesPerSegment);
                dataSegment(1,:) = segmentE;
                dataSegment(2,:) = segmentN;
                dataSegment(3,:) = segmentZ;
                
                uTS = UniformTimeSeries(dataSegment, sacSampleRate);
                uTSResample = uTS.resample(sampleRate);
                cTimeSeries{i} = uTSResample;
            end
        end
        
        
        
        % ---------------------------------------------------------------
        
        function onset = ...
                getSacOnsetSegment(sacRecord, w1, w2, threshold)
            %
            %
            %
            % Input:
            %   w1 - duration (seconds) of data preceding event to return.
            %   w2 - duration (seconds) of data after event to return.
            %   threshold - threshold on absolute amplitude to trigger detection of onset
            %
            % Output:
            %    onset - UniformTimeSeries object, if an onset is detected,
            %    otherwise {}.
            %
            import synthetic.*
            import phone.*
            import sac.*
            import timeSeries.*
            import check.*   

            
            % check for an onset
            
            magnitude = sacRecord.getMagnitude();
            
            index = find(abs(magnitude) >= threshold, 1);
            
            if isempty(index)
               % no onset detected
               onset = {};
               return;
            end
            
            
            
            % extract the period of time around the onset
            
            % this is kind of dirty...
            secondsPerSample = 1/sacRecord.sampleRate;
            onsetTime = (index-1) * secondsPerSample;
            
            startTime = onsetTime - w1;
            endTime = onsetTime + w2;
            
            recordTimeSeries = sacRecord.getTimeSeries();
            
            segmentData = recordTimeSeries.getInterval(startTime, endTime);
            
            % create a UniformTimeSeries object
            
            onset = UniformTimeSeries(segmentData, sacRecord.sampleRate, 0);
        end
        
        % ---------------------------------------------------------------
        
        function a = maxAbsAmplitude(timeSeries)
            % 
            % Input: 
            %   timeSeries - TimeSeries
            % 
            % Output:
            %   a - maximum L2 norm of any data point in the time series
            
            X = timeSeries.X;
            
            % compute the L2 norm of each column (data point)
            % The abs isn't necessary for real data.
            N = sqrt(sum(abs(X).^2));
            a = max(N);
        end
        
        % ---------------------------------------------------------------
  
    end
    % ====================================================================
    
end

