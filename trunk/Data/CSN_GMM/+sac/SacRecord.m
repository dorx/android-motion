classdef SacRecord
    % SacRecord - groups E, N, and Z data components (SAC files) for a
    % seismic event.
    %   
    % author: Matt Faulkner
    %
    
    % ====================================================================
    
    properties
        nWaveform   % SacWaveform
        eWaveform   % SacWaveform
        zWaveform   % SacWaveform
        
        sampleRate  % sample rate, assumed the same for all waveforms
    end
    
    % ====================================================================
    
    methods
        
        % ---------------------------------------------------------------
        
        function obj = SacRecord(eFileName, nFileName, zFileName)
            % constructor
            %
            % Input:
            %   eFileName - path to a --e.sac file
            %   nFileName - path to a --n.sac file
            %   zFileName - path to a --z.sac file
            %
            % Assumes that all three SAC files have same number of points,
            % same sample rate, same units, etc.
            %
            
            % might want to check that all three files have the same "root"
            import sac.*
            import check.*
            
            obj.eWaveform = SacWaveform(eFileName);
            obj.nWaveform = SacWaveform(nFileName);
            obj.zWaveform = SacWaveform(zFileName);
            
            obj.sampleRate = obj.eWaveform.sampleRate;
            
            % TODO: check that all three have the same number of points,
            % same sample rate, etc.
            
            % these should each be a column vector, of the same length
            eAccel = obj.eWaveform.accel;
            nAccel = obj.nWaveform.accel;
            zAccel = obj.zWaveform.accel;
            
            assert(isColumnVector(eAccel))
            assert(isColumnVector(nAccel))
            assert(isColumnVector(zAccel))
            
            % check sample rates
            
            eFs = obj.eWaveform.sampleRate;
            nFs = obj.nWaveform.sampleRate;
            zFs = obj.zWaveform.sampleRate;
            
            if (eFs ~= nFs) || (eFs ~= zFs)
                 e = MException('SacRecord:SacRecord', 'acceleration channels have different sample rates. e: %f, n: %f, z: %f', ...
                     eFs, nFs, zFsLength);
                throw(e);
            end
            
            % check data lengths to be within some tolerance of each other
            lengthTolerance = 0.05;
            
            eLength = length(eAccel);
            nLength = length(nAccel);
            zLength = length(zAccel);
            
            lengths = [eLength; nLength; zLength];
            maxLength = max(lengths);
            minLength = min(lengths);
            
            if minLength < (1 - lengthTolerance)*maxLength
                disp(eFileName)
                disp(nFileName)
                disp(zFileName)
                e = MException('SacRecord:SacRecord', 'acceleration channels have different lengths. e: %d, n: %d, z: %d', eLength, nLength, zLength);
                throw(e);
            end
            
            % at this point, channels should have the same sample rates,
            % and nearly the same number of data points. Truncate the data
            % so that they have the same data lengths
            
            obj.eWaveform.accel = obj.eWaveform.accel(1:minLength);
            obj.nWaveform.accel = obj.nWaveform.accel(1:minLength);
            obj.zWaveform.accel = obj.zWaveform.accel(1:minLength);
            
        end
        
        % ---------------------------------------------------------------
            
        function [A, Fs]= getAcceleration(obj)
            % 
            % Output:
            %   A - 3xn matrix. Each column is an E,N,Z data point
            %   Fs - sample rate
            %
            import sac.*
            import check.*
            
            % these should each be a column vector, of the same length
            eAccel = obj.eWaveform.accel;
            nAccel = obj.nWaveform.accel;
            zAccel = obj.zWaveform.accel;
            
            assert(isColumnVector(eAccel))
            assert(isColumnVector(nAccel))
            assert(isColumnVector(zAccel))
            
            eLength = length(eAccel);
            nLength = length(nAccel);
            zLength = length(zAccel);
            
            
            assert(eLength == nLength)
            assert(eLength == zLength)
            
            A = zeros(3, eLength);
            A(1,:) = eAccel';
            A(2,:) = nAccel';
            A(3,:) = zAccel';
            
            Fs = obj.sampleRate;
        end
        
        % ---------------------------------------------------------------
        
        function timeSeries = getTimeSeries(obj)
            %
            %
            %
            import  sac.*
            import timeSeries.*
            
            [A, Fs] = obj.getAcceleration();
            
            % arbitrary choice
            startTime = 0;
            
            timeSeries = UniformTimeSeries(A,Fs, startTime);
            
        end
        
        % ---------------------------------------------------------------
        
        function magnitude = getMagnitude(obj)
           % getMagnitude - L2 norm of E,N,Z data.
           %
           % Output:
           %    magitude - column vector of absolute magnitudes. Maybe this
           %    should be a UniformTimeSeries object?
           %
           import sac.*
           import check.*

           A = obj.getAcceleration;
           
           % compute the L2 norm of each column (data point)
           % The abs isn't necessary for real data.
           % The one explicitly specifies that the columns should be
           % summed. This is an issue if there's only one row (Matlab will
           % then sum the row).
           magnitude = transpose(sqrt( sum(abs(A).^2,1) ));
           
           assert(isColumnVector(magnitude))
           
        end
        
        % ---------------------------------------------------------------
        
        function obj = scaleToPeakAmplitude(obj, peakAmplitude)
           % scale E,N,Z channels to give the desired peak amplitude
           %
           % Input:
           %    peakAmplitude - m/s^2
           %
           import sac.*
           magnitude = obj.getMagnitude();
           maxAbsMag = max(magnitude);
           
           if maxAbsMag == 0
               return
           end
           scaleFactor = peakAmplitude / maxAbsMag;
           
           % need to square this in order to scale each component
           obj.eWaveform = obj.eWaveform.scaleMultiplicative(scaleFactor);
           obj.nWaveform = obj.nWaveform.scaleMultiplicative(scaleFactor);
           obj.zWaveform = obj.zWaveform.scaleMultiplicative(scaleFactor);
           
        end
        
        % ---------------------------------------------------------------
        
        function d = distanceToEvent(obj)
            %
            % Output:
            %   d - Distance to epicenter, in km
            %
            import sac.*
            
            d = obj.eWaveform.distanceToEvent();
        end
            
        
        % ---------------------------------------------------------------
        
        function m = eventMagnitude(obj)
            % Magnitude of event
            %
            %
            import sac.*
            
            m = obj.eWaveform.eventMagnitude();
        end
        
        
        % ---------------------------------------------------------------
        
        function length = getLength(obj)
            length = obj.eWaveform.lengthSeconds;
        end
        
    end
    
    % ====================================================================
    
end

