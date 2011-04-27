function [X, Y, Z, t] = readData(filename, varargin)

% This function takes in a .acsn file and outputs the X, Y, Z values as
% well as the time stamps into 4 column vectors. The time values in the
% file are in nanoseconds(maybe miliseconds...) since the phone has turned
% on. If you use a second argument, which is optional and can be anything, 
% to the function, you also get a plot of the time series all on one plot.

% Note that if the file is not readable, it's probably because the phone
% turned off before completely recording the last line of data. You can
% simply delete the last row of data in the .acsn file manually to fix the 
% problem.

D = load(filename);
X = D(:, 1);
Y = D(:, 2);
Z = D(:, 3);
t = D(:, 4);
t = t - t(1);

if nargin > 1
    figure(1)
    plot(t, X, t, Y, t, Z)
    legend('X', 'Y', 'Z')
end

end