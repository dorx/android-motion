inFilename  = 'bikejon.acsn';
outFilename = 'featbike.txt';


% Get and prepare data
rawData = load(inFilename, ' ');

% Size of each window and amount to slide.
windowSize = 2;
windowStep = .5;

% Get sliding sliding windows.
rawWindows = slidingWindows(rawData, windowSize, windowStep);

% Remove Gravity
rGrav = removeGravity(rawWindows);

% Transform each window in a feature vector and APPEND each to file
s = size(rGrav);
length = s(2);

for i = 1 : length
    feat = features(rGrav{i}, 10, 3);
    dlmwrite(outFilename, reshape(feat,1,[]), '-append','delimiter','\t');
end

%features(rGrav{b},10, 3);
%features(bikeWindow{14}, 10, 10);
%a = 255

%bikeWindows{14}(1:a,1:3)
%rGrav{14}(1:a,1:3)

%bikeWindows{14}(1:a,1:3) - rGrav{14}(1:a,1:3)

%g = mean(bikeWindows{14}(1:a,1:3))
%norm(g)