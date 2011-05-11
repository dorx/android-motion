function [] = plotLog(filename)
%plotLog
%   Plots data from an accelerometer log file.  Gravity is not removed.
%   Saves a .fig in the directory given.
%   Arguments:
%       filename - Name of log file to plot

% Get data from file.
rawData = load(filename, ' ');
% Convert nanoseconds to seconds and start time at 0
startTime = rawData(1, 4);
rawData(:, 4) = 1e-9 * (rawData(:, 4) - startTime);
xData = rawData(:, 1);
yData = rawData(:, 2);
zData = rawData(:, 3);
tData = rawData(:, 4);

% Make plots
% x
subplot(2, 2, 1);
plot(tData, xData);
title('X-Axis Accelerations');
xlabel('Time (sec)');
ylabel('Acceleration (m/s^2)')

% y
subplot(2, 2, 2);
plot(tData, yData);
title('Y-Axis Accelerations');
xlabel('Time (sec)');
ylabel('Acceleration (m/s^2)')

% z
subplot(2, 2, 3);
plotHandle = plot(tData, zData);
title('Z-Axis Accelerations');
xlabel('Time (sec)');
ylabel('Acceleration (m/s^2)')


% Get filename to save and save file
splitFilename = regexp(filename, '\.', 'split');
baseFilename = splitFilename{1};
saveas(plotHandle, baseFilename, 'fig');

end
