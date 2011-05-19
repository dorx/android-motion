function [ type, confidence ] = voting2( file, weights )
%voting2 First voting algorithm
%   Takes a file, converts to raw data and reduces it
%   using the other algorithms
%   runs motion learning on it
%   outputs a string corresponding to the activity
%   weights is the matrix of weight matrices, as produced by
%   getWeights()
rawData = load(file);
x = size(rawData,1)
newData = reduction5(rawData);
x = size(newData,1)
newData = newData';
% Load data and reduce; take transpose of matrix so classify3Layer can 
% handle it

type = 'Unknown'; % Default type; for if we can't figure it out
results = zeros(6, 6, x); % There should be 30 types of classifications
for i=1:6
    for j=1:6
        if i==j
            continue
        end
        w1 = weights{i,j,1};
        w2 = weights{i,j,2};
        w3 = weights{i,j,3};% get the weights for this 
        results(i,j,:) = classify3Layer(newData, w1, w2, w3);
        % Classify them; this should give us a number between 0 and 1
        % for each piece of data
    end
end

avgResults = zeros(6,6);
for i=1:6
    for j = 1:6
        if i==j
            continue
        end
        n=0;
        for k=1:x
            n = n + results(i,j,k);
        end
        n = n / x;
        avgResults(i,j) = n;
    end
end
% Get the average of all the results for each type of classification.

avgResults

activity = zeros(6);
for i=1:6
    for j = 1:6
        if i==j
            continue
        end
        activity(i) = activity(i) + avgResults(i,j);
    end
    activity(i) = activity(i) / 5;
end
% Take the average of the comparisons between each type of activity; 
% this would give us the average of the 5 probabilities when comparing
% a given activity to any other activity

[m,i] = max(activity);
% Get the highest rated activity; m is the highest value, i is the
% index of that activity
m=m(1);
i=i(1);
actTypes = ['Walking   '; 'Running   '; 'Idling    '; 'Upstairs  '; 'Downstairs'; 'Biking    '];
actTypes = cellstr(actTypes);
if m > 0.5
    confidence = m;
    type = actTypes(i);
    
else
    confidence = 1 - m;
end
% The highest ranked activity is our guess; that rank becomes our 
% confidence in that guess.  The threshold is 0.5; below that we
% declare uncertainty


end


