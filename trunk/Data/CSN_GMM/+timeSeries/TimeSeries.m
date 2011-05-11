classdef TimeSeries
    % TimeSeries - interface
    %
    %
    % author: Matt Faulkner
    %
    methods (Abstract)
        % Output:
        %   s - duration of time series, in seconds.
        s = lengthSeconds(obj)
        
        
        % Input:
        %   Fresample - desired sample rate
        %
        % Output:
        %   xResample - (column vector) values of resampled time series
        %   tResample - (column vector) times of resampled values
        [xResample, tResample] = getResampledValues(obj, fResample)
    end
    
end

