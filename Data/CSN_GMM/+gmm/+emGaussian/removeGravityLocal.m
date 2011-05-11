function [newData] = removeGravityLocal(data, locality)
% REMOVEGRAVITYLOCAL
% 
% Removes gravity and rotates so that gravity is in the -z direction.
%
% Inputs:
%   data - An Nx4 matrix of data, where each row is a point, with time in the
%       fourth component.
%   locality - Floating point value in [0,1] specifying how local gravity
%       should be.
%
% Outputs:
%   gRemoved - An Nx4 matrix of data with gravity removed

% Default argument for locality
if nargin == 1
    locality = .05;
end

numPoints = size(data, 1);

% Find the average norm (magnitude of gravity).
normSum = 0;
for i = 1 : numPoints
    normSum = normSum + norm(data(i, 1 : 3));
end

gravitySize = normSum / numPoints;

gravity = data(1, 1 : 3);
newData = zeros(numPoints, 4);

% Copy in times
newData(:, 4) = data(:, 4);

for i = 1 : numPoints
    point = data(i, 1 : 3);
    gravity = (1 - locality) * gravity + locality * point;
    rotatedPoint = rotateVecToVec(point, gravity, [0, 0, -1], 1); % Rotate
    rotatedPoint = rotatedPoint - [0, 0, -gravitySize]; % Remove gravity
    newData(i, 1 : 3) = rotatedPoint;
end

end

