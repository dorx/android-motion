function windows_g_removed= removeGravity(windows)
% REMOVEGRAVITY
% 
% Removes the gravity vector from a cell array of time windows of readings
%
% Inputs:
% A cell array of matrices of x,y,z,t data (in the format that 
% slidingWindows returns)
%
% Outputs:
% Another cell array of matrices of x,y,z,t data with gravity removed

windows_g_removed = [];

% Initialize the first guess at the gravity vector by the average of 
% the vectors
g_vector = mean(windows{1}(:, 1:3));

s = size(windows);
length = s(2);

for i = 1 : length
    % Calculate a new gravity vector at this time window
    new_g_vector = mean(windows{i}(:, 1:3));
    
    % Move the guess at the gravity vector to the new gravity vector
    g_vector = rotateVecToVec(g_vector, g_vector, new_g_vector, .75);
    
    % Rotate the data points of this section to make to the gravity vector
    % point to (0, 0, -1)
    data = [];
    
    s = size(windows{i});
    windowLength = s(1);
    window = windows{i};
    
    for j = 1 : windowLength
        rotated = [rotateVecToVec(window(j,1:3), g_vector, [0, 0, -1],1)...
                   window(j, 4)];
        rotated = rotated + [0, 0, 9.80665, 0];
        data = [data ; rotated];
    end
       
    windows_g_removed = [windows_g_removed {data}];
    
end

end

