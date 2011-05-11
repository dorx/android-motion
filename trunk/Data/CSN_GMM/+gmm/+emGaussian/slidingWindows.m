function windows = slidingWindows(data, size, step)
% Input:
%   data - The data to separate into sliding windows.  In one row, data is
%          given as [x, y, z, t].
%   size - The size (in seconds) of each sliding window
%   step - Difference in starting time between sucessive sliding windows
%
% Ouput:
%   windows - A 'cell array' of data, organized in sliding windows.

% Nanoseconds (given) in a second.
second = 1000000000;

% Adjust size and step
size = size * second;
step = step * second;

windows = [];

% Time bounds
time_min = data(1, 4);
time_max = data(end, 4);


% Sliding windows are determined by their start time and duration
% Here, we use start times
beginIndex = 1;
endIndex = 1;
for tStart = time_min : step : time_max - size
    tStop = tStart + size;
    % Find first index in time window
    for i = beginIndex : length(data)
        if data(i, 4) >= tStart
            beginIndex = i;
            break
        end
    end
    % Find last index in time window
    for i = endIndex : length(data)
        if data(i, 4) >= tStop
            endIndex = i;
            break
        end
    end
    % Add range to windows
    windows = [windows {data(beginIndex : endIndex, :)}];
end