function [Xtrain, Ytrain] = rawTrainingDataOVOld(rootDir, user, act1, act2)

% Makes raw data segments of length ~ 5s for specified user and activity
% This function goes through every single .acsn file containing data made 
% by the user doing either act1 or act2 in the rootDir and make raw data 
% segments from the data in the file. A segment gets a label of "1" if it 
% is act1 or "0" if it is act2; Each row in Xtrain corresponds to a data 
% segment and is a concatenation of the 3 axes.
%
% Output:
%  Xtrain: data segments. dimension = numOfSegments x 650*3
%  Ytrain: labels.        dimension = numofSegments x 1

l = ls(rootDir);
N = size(l, 1);
Xtrain = [];
Ytrain = [];

for i=1:N
    fname = l(i,:);
    if ~isdir(fname)
        s = strsplit(fname(1:end-5), '_');
        if strcmp(s(1), user)
            if strcmp(s(2), act1) || strcmp(s(2), act2)
                if strcmp(s(2), act1)
                    label = 1;
                else
                    label = 0;
                end
                [X, Y, Z, t] = readData(fullfile(rootDir,fname));
                % exclude the first and last 10 seconds of data
                % data is recorded every ~8 miliseconds
                % 5 seconds ~ 650 datapoints
                numSegs = int32((length(X) - 4*650)/650);
                xtrain = zeros(numSegs, 650*3);
                ytrain = ones(numSegs, 1)*label;

                for j=1:numSegs
                    datapt = zeros(1, 650*3);
                    datapt(1:650) = X((j+2)*650+1:(j+3)*650);
                    datapt(651:650*2) = Y((j+2)*650+1:(j+3)*650);
                    datapt((650*2)+1:650*3) = Z((j+2)*650+1:(j+3)*650);
                    xtrain(j,:) = datapt;
                end

                Xtrain = vertcat(Xtrain, xtrain);
                Ytrain = vertcat(Ytrain, ytrain);
            end
        end
    end
end
end