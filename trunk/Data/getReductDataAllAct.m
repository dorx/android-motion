function [ TRAIN, TEST ] = getReductDataAllAct( user )

%{

DESCRIPTION:
    Get all activity data for a given user. ALL is splitted into TRAIN 
    set (80%) and TEST set (20%). 

RETURNS:
    ALL   : An [nacts, 1] cell, where nacts = number of activities.
            ALL{i} = 
                [ nintervals (a.k.a. # of 5 seconds chunk for activity i) x 
                  650*3 ]
    TRAIN : Training set; an [nacts, 1] cell. It's a proper subset of ALL.
    TEST  : Test set; an [nacts, 1] cell. It's a proper subset of ALL.

%}

possibleActs = ['walking   ';
                'running   ';
                %'sitting   ';
                'idling    ';
                %'upstairs  ';
                %'downstairs';
                'biking    '];
possibleActs = cellstr(possibleActs);


possibleUsers = ['Alex  ';
                'Daiwei';
                'Doris ';
                'Robert';
                'Wenqi '];
            
possibleUsers = cellstr(possibleUsers);


% Check the input user is valid.
valid_user = false;
for i = 1 : length(possibleUsers)
    if strcmp(user, possibleUsers{i})
        valid_user = true;
        break;
    end
end

if ~valid_user
    error('please enter a valid user name.');
end


% Prepare for data retrieval.
rootDir = 'SensorRecordings';
nacts = length(possibleActs);


TRAIN = cell(nacts,1);
TEST  = cell(nacts,1);

ndata_peract_train = cell(nacts, 1);
ndata_peract_test  = cell(nacts, 1);

% trainset/testset will contain training/test data from all activities
trainset = [];
testset = [];

% Concatenate all data for PCA
for i = 1 : nacts
    
    % Get the activity name (string) to feed into rawTrainingDataOVO_unix
    act = possibleActs{i};

    % X is a [nintervals, 1950] matrix. nintervals = the number of 5 second intervals.
    [X, Y] = rawTrainingDataOVO_unix(rootDir, user, act, 'none-existing activity');
    
    % Split the data into TRAIN and TEST
    nintervals = size(X, 1);
   
    % # of training data.  (The first 80%)
    ntrain = int32(nintervals * 0.8);
    
    % Record the # of training data and test data
    ndata_peract_train{i} = ntrain;
    ndata_peract_test{i}  = nintervals - ntrain;
    
    % Concatenate (vertically) the splitted X to trainset and testset
    trainset = [trainset ; X(1:ntrain, :)];
    testset  = [testset  ; X((ntrain + 1) : nintervals, :)];

end

    
% Reduce data (on training/test data from all activities).
redtrainset = reduce(trainset);
redtestset = reduce(testset);

% Split the PCA reduced data into four activities.
counter_trainset = 1;
counter_testset = 1;

for i = 1 : nacts
    TRAIN{i} = redtrainset(counter_trainset : counter_trainset + ndata_peract_train{i} - 1, :);
    TEST{i} = redtestset(counter_testset : counter_testset + ndata_peract_test{i} - 1, :); 
    
    % advance counters
    counter_trainset = counter_trainset + ndata_peract_train{i};
    counter_testset = counter_testset + ndata_peract_test{i};
end



end





function redMat = reduce(X)
%{

ARGUMENT:
    X      : raw data of dimensions [nintervals x (650*3)].

RETURN: 
    redMat : a matrix of dimensions [nintervals x nfeatures].

%}

    
    nintervals = size(X, 1);
    
    nfeatures = 64;     % Need a better way to find out this value.
    
    % fmat is the feature matrix that fead into PCA reduction
    fmat = zeros(nfeatures, nintervals);
    
    % See the feature...
    avg_freq = zeros(nfeatures, 1);
    
    
    % For each 5 second interval, get a feature vector. Save the result to
    %   fmat (of dimensions [nfeatures x nintervals])
    for i = 1 : nintervals
    
        % Xvec is an [3, 650] matrix, representing the data for a 5 sec
        %   interval. That is, each column is a time series datum.


        
        Xvec = X(i, :);     % size(Xvec) = [1, 1950]
        
        
        
        
        % This part uses timeSeries to generate frequency features.
%{
        Xvec = reshape(Xvec, int32(length(Xvec) / 650), 650); % size(Xvec) = [3, 650]
        

        
        % Applying reduction.
        
        % Create UniformTimeSeries object
        Fs = 125;           % 125 samples per second.
        startTime = 0;      % We do not need start time.
        uTimeSeries = timeSeries.UniformTimeSeries(Xvec, Fs, startTime);
        
        % Create XyzFeature object
        nFreqZ = 10;
        nMomZ  = 10;
        xyzf = feature.XyzFeature(uTimeSeries,  nFreqZ, nMomZ); % optional: nFreqXY, nMomXY, label);
        
        fmat(:, i) = xyzf.featureVector;
        
%}
        
        % We instead use naive first 64 FFT frequencies as our feature
        %   vector.
        Xvec = reshape(Xvec, int32(length(Xvec)/3),3);  %size(Xvec) = [650 x 3]
        xmag = sqrt(Xvec(:, 1).^2 + Xvec(:, 2).^2 + Xvec(:, 3).^2);
        
        % These two components are in reduction3, but it lacks theoretical
        % basis as feature.
        %mean((1:650) .* (fA' / norm(fA))), 
        %std((1:650) .* (fA' / norm(fA)))
        
        fmat(:,i) = abs(fft(xmag, nfeatures));
        
        avg_freq(:,1) = avg_freq(:,1) + fmat(:,i);
        
        
    end
    
    
    % Carry out PCA reduction on feature matrix (each column is a data point).
    [C, mu, sigma] = feature.PcaFeature.computePcaParameters(fmat);
    k = 16;     % Take the first 16 principle components
    F =  feature.PcaFeature.PcaReduce(fmat, C, mu, sigma, k);   % each row is a reduced data point.
    redMat = F(1:k, :);    % the (k+1)th component is the projected error, which we get rid of.
    redMat = redMat';
    
end

