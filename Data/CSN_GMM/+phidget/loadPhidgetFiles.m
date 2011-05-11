function uTS = loadPhidgetFiles( xFile, yFile,  zFile, sampleRate, countsToMs2 )
% loadPhigdetFiles - load x,y,z text files of phidget data. Throws
% exception if any file is not found.
%
% Input:
%   xFile - path to a phidget data file for x channel
%   yFile - path to a phidget data file for y channel
%   zFile - path to a phidget data file for z channel
%   sampleRate - samplesPerSecond of data files
%   countsToMs2 - conversion factor from phidget counts to meters per
%       second squared.
%
% Output:
%   uTS - UniformTimeSeries object
%

import phidget.*
import check.*
import timeSeries.*

% ------------------------------------------------------------------------

if nargin == 3
    % defaults for 16 bit phidget, as of Oct. 24, 2010
    sampleRate = 250;
    countsToMs2 = 9.8 * 2.5 / (2^15);
end


% check that xFile, yFile, zFile exist
if ~isfile(xFile)
    err = MException('loadPhidgetFile:xFile invalid', ...
        'value is not a file?');
    throw(err)
end

if ~isfile(yFile)
    err = MException('loadPhidgetFile:yFile invalid', ...
        'value is not a file?');
    throw(err);
end

if ~isfile(zFile)
    err = MException('loadPhidgetFile:zFile invalid', ...
        'value is not a file?');
    throw(err);
end

% ------------------------------------------------------------------------

xData = load(xFile);
xData = xData * countsToMs2;

yData = load(yFile);
yData = yData * countsToMs2;

zData = load(zFile);
zData = zData * countsToMs2;

% these should each be the same length. If not, just truncate.
lengths = [size(xData,1), size(yData,1), size(zData,1)];
minLength = min(lengths);

X = zeros(minLength, 3);
X(:,1) = xData(1:minLength);
X(:,2) = yData(1:minLength);
X(:,3) = zData(1:minLength);

% put in "each column is a data point" form
X = X';

% create a UniformTimeSeries object.

startTime = 0;
uTS = UniformTimeSeries(X, sampleRate, startTime);

% ------------------------------------------------------------------------