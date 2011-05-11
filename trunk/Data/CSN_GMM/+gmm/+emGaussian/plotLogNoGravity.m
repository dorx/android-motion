function [] = plotLogNoGravity(filename)
%plotLog
%   Plots data from an accelerometer log file.  Points are rotated so that
%   gravity points in the -z direction, and gravity is removed.
%   Arguments:
%       filename - Name of log file to plot

% Get data from file.
rawData = load(filename, ' ');
% Remove gravity and do rotations
data = removeGravityLocal(rawData, .05);

% Convert nanoseconds to seconds and start time at 0
startTime = data(1, 4);
data(:, 4) = 1e-9 * (data(:, 4) - startTime);
xData = data(:, 1);
yData = data(:, 2);
zData = data(:, 3);
tData = data(:, 4);

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
plot(tData, zData);
title('Z-Axis Accelerations');
xlabel('Time (sec)');
ylabel('Acceleration (m/s^2)')

end
