classdef SacWaveform
    % SacWaveform - embodies as SAC (Seismic Analysis Code) file.
    %   A SAC file is a single data component recorded at a single seismic
    %   location, such as "z axis acceleration at station 14".
    %
    % See http://geophysics.eas.gatech.edu/classes/SAC/ for SAC info
    %
    % author: Matt Faulkner
    %
    
    % ====================================================================
    
    properties
        fileName    % name of source SAC file
        header      % header from SAC file
        axis        % "e", "n", or "z"
        accel       % acceleration in m/s^2. Column vector.
        sampleRate  % average samples per second. Scalar.
        rawData
    end
    
    % ====================================================================
    
    methods
        
        % ---------------------------------------------------------------
        
        function obj = SacWaveform(sacFile)
            % Constructor
            %
            % Input: 
            %   sacFile - path to a SAC file
            import sac.*
            import java.lang.String
            
            [acceleration, Fs, sacHeader, data] = SacLoader.loadSacFile(sacFile);
            
            obj.fileName = sacFile;
            obj.header = sacHeader; 
            obj.rawData = data;
            
            % java
            nameString = String(sacFile);
            nameString = nameString.toLowerCase();
            
            if nameString.endsWith('z.sac')
                obj.axis = 'z';
            elseif nameString.endsWith('e.sac')
                obj.axis = 'e';
            elseif nameString.endsWith('n.sac')
                obj.axis = 'n';
            else
                error('sacFile does not end with n.sac, e.sac, or z.sac')
            end

            obj.accel = acceleration;
            obj.sampleRate = Fs;
            
        end
        
        % ---------------------------------------------------------------
        
%         function segment = getInterval(obj, t0, t1)
%             % getInterval - get a sub-segment of w1 seconds before and w2 seconds after
%             %   the n-th point of X. Pad with zeros if necessary
%             %
%             % Input:
%             %   t0 - start time, seconds
%             %   t1 - end time, seconds
%             %
%             % Output:
%             %   segment - uniform time series object, containing the data
%             %   of the SacWavefrom from t0 to t1, padded with zeros if
%             %   necessary. The data is at the same sample rate.
%             %
%             %
%             
%             
%             
%             
%             
%             
%             
%             
%         end
        
        % ---------------------------------------------------------------
        
        function timeSeries = getTimeSeries(obj)
           %
           %
           %
           import sac.*
           import timeSeries.*
           
           % convert from a column vector of data to "each column is a data
           % point" format
           data = transpose(obj.accel);
           
           % this is an arbitrary choice...
           startTime = 0;
           
           timeSeries = UniformTimeSeries(data, obj.sampleRate, startTime);
           
        end
        
        % ---------------------------------------------------------------
        
        function [n,e] = getStationLocation(obj)
           % get the header's station location
           %
           % Output:
           %    n - station location, decimal degrees north latitude
           %    e - station location, decimal degrees east longitude
           %
           import sac.*
           
           n = obj.header.station.stla;
           e = obj.header.station.stlo;
        end
        
        % ---------------------------------------------------------------
        
        function [n,e] = getEventLocation(obj)
           %
           % Output:
           %    n - event location, decimal degrees north latitude
           %    e - event location, decimal degrees east longitude
           %
           import sac.*
           
           n = obj.header.event.evla;
           e = obj.header.event.evlo;
        end
        
        % ---------------------------------------------------------------
        
        function d = distanceToEvent(obj)
           % The distance between the station and the event epicenter, km.
           %
           % Output:
           %    d - Distance, in km
           %
           import sac.*
           import haversine.*
           
           [stationLat, stationLong] = obj.getStationLocation();
           [eventLat, eventLong] = obj.getEventLocation();
           
           loc1 = [stationLat, stationLong];
           loc2 = [eventLat, eventLong];
           
           d = haversine(loc1, loc2);
        end
        
        % ---------------------------------------------------------------
        
        function m = eventMagnitude(obj)
           % This might be in 'local magnitude' or 'moment magnitude'
           %
           import sac.*
           m = obj.header.event.mag;
        end
        
        % ---------------------------------------------------------------
        
        function s = lengthSeconds(obj)
           import sac.*
           import timeSeries.*
           
           timeSeries = obj.getTimeSeries();
           s = timeSeries.lengthSeconds();
        end
        
        % ---------------------------------------------------------------
        
        function obj = scaleToPeakAmplitude(obj, peakAmplitude)
           % scale the acceleration data to have the desired peak amplitude
           %
           % Input
           %    peakAmplitude - desired peak amplitude, in m/s^2. (scalar)
           %
           import sac.*
           assert(isscalar(peakAmplitude))
           
           % get maximum absolute acceleration. 
           % scale
           % return a new object? modify this object?
           maxAbsAccel = max(abs(obj.accel));
           
           if maxAbsAccel == 0
               return
           end
           
           scaleFactor = peakAmplitude / maxAbsAccel;
           obj.accel = obj.accel * scaleFactor;
           
        end
        
        % ---------------------------------------------------------------
        
        function obj = scaleMultiplicative(obj, scaleFactor)
            % scale acceleration using a multiplicative factor
            %
            % Input:
            %   scaleFactor - m/s^2
            %
            import sac.*
            assert(isscalar(scaleFactor))
            
            obj.accel = obj.accel * scaleFactor;
            
        end
        % ---------------------------------------------------------------
    
    end
    
    % ====================================================================
    
end

