function [ ALL, TRAIN, TEST ] = getReductDataAllAct( user )
%{

DESCRIPTION:
    Get all activity data for a given user. ALL is splitted into TRAIN 
    set (80%) and TEST set (20%). 

RETURNS:
    ALL   : An [nacts, 1] cell, where nacts = number of activities.
            ALL{i} = 
                [ nintervals (a.k.a. # of 5 seconds chunk for activity i), 
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

ALL   = cell(nacts,1);
TRAIN = cell(nacts,1);
TEST  = cell(nacts,1);


for i = 1 : nacts
    
    act = possibleActs{i};
    % X is a [nintervals, 1950] matrix. nintervals = the number of 5 second intervals.
    [X, Y] = rawTrainingDataOVO_unix(rootDir, user, act, 'none-existing activity');
    
    
    % Reduce data.
    %   ALL{i} : [nintervals, nfeatures]
    ALL{i} = reduce(X);
    
    % Split the data into TRAIN and TEST
    nintervals = size(ALL{i}, 1);
    
    % # of training data.
    ntrain = int32(nintervals * 0.8);
    
    TRAIN{i} = ALL{i}( 1 : ntrain, :);                  % The first 80%
    TEST{i}  = ALL{i}( (ntrain + 1) : nintervals, :);    % The remaining 20%

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
    nfeatures = 42;     % Need a better way to find out this value.
    
    % fmat is the feature matrix that fead into PCA reduction
    fmat = zeros(nfeatures, nintervals);
    
    
    % For each 5 second interval, get a feature vector. Save the result to
    %   fmat (of dimensions [nfeatures x nintervals])
    for i = 1 : nintervals
    
        % Xvec is an [3, 650] matrix, representing the data for a 5 sec
        %   interval. That is, each column is a time series datum.
        Xvec = X(i, :);     % size(Xvec) = [1, 1950]
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
        
    end
    
    
    % Carry out PCA reduction on xyzf
    [C, mu, sigma] = feature.PcaFeature.computePcaParameters(fmat);
    k = 16;     % Take the first 16 principle components
    F =  feature.PcaFeature.PcaReduce(fmat, C, mu, sigma, k);
    redMat = F(1:k, :);    % the (k+1)th component is the projected error.
    redMat = redMat';
    
end

