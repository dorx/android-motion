function plot_freq_allact( user )

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

ndata_peract_train = cell(nacts, 1);
freq = cell(nacts,1);


% Concatenate all data for PCA
for i = 1 : nacts
    
    % Get the activity name (string) to feed into rawTrainingDataOVO_unix
    act = possibleActs{i};

    % X is a [nintervals, 1950] matrix. nintervals = the number of 5 second intervals.
    [X, Y] = rawTrainingDataOVO_unix(rootDir, user, act, 'none-existing activity');
    
    % Split the data into TRAIN and TEST
    nintervals = size(X, 1);
   
    ntrain = int32(nintervals);
    
    % Reduce data (on training/test data from all activities).
    freq{i} = reduce(X(1:ntrain, :));

end


    % Plot single-sided amplitude spectrum.
    Fs = 650 / 5;   % Sampling frequency
    %NFFT = 2^nextpow2(650); % Next power of 2 from length of y
    NFFT = 64;
    f = Fs/2*linspace(0,1,NFFT/2+1);
    semilogy(f', freq{1}, f', freq{2}, f', freq{3}, f', freq{4});
    legend('walking', 'running', 'idling', 'biking');
    title('Amplitude Spectrum');
    xlabel('Frequency (Hz)');
    ylabel('Amplitude');
    


end





function avg_freq = reduce(X)
%{

ARGUMENT:
    X      : raw data of dimensions [nintervals x (650*3)].

RETURN: 
    redMat : a matrix of dimensions [nintervals x nfeatures].

%}

    
    nintervals = size(X, 1);
    
    %NFFT = 2^nextpow2(650); % Next power of 2 from length of y
    NFFT = 64;
    nfeatures = NFFT;     % Need a better way to find out this value.
    
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
    
    %L = 650;        % length of the signal.
    Fs = 650 / 5;   % Sampling frequency
    f = Fs/2*linspace(0,1,NFFT/2+1);
    
    avg_freq = avg_freq./nintervals;
    avg_freq(1) = 0;        % zero the 0 frequency
    avg_freq = 2*avg_freq(1:NFFT/2+1);
    

end

