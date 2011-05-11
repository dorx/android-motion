% Process the records from the 9-24 shake table experiment. 

%clear all; close all;

import phone.*
import timeSeries.*
import shakeTable.*

% the intended peak amplitude of each recording (as recorded in the file names):
intendedAmplitudes = [0.84009, 0.86076, 0.83004; 0.36346, 0.43640, 0.15611; 0.47849, 0.61116, 0.24508]; % in g
intendedAmplitudes = intendedAmplitudes * 9.806;


% For "Android B", the records are (ls -m is helpful here)
% I've made each row a "triplet"
androidFilesB = ...
    {'1.e.acsn', '1.n.acsn', '1.z.acsn'; '4.e.acsn', '4.n.acsn', '4.z.acsn'; '5.e.acsn', '5.n.acsn', '5.z.acsn'};

% I think these are the backpack recordings
 names = {'1A-combined', '4A-combined', '5A-combined'};
 root = 'data/shakeTable_9-24-2010/android_A';

% I think these are the on table recordings
%names = {'1B-combined', '4B-combined', '5B-combined'};
%root = 'data/shakeTable_9-24-2010/android_B';


w1 = 5; % seconds
w2 = 25; % seconds
thresholds = [1, 1, 1]; % m/s^2
channel = 1;

numTriples = size(androidFilesB,1);

cRecords = cell(numTriples,1);

for i=1:numTriples
    triple = androidFilesB(i,:);
    ePath = [root '/' triple{1}];
    nPath = [root '/' triple{2}];
    zPath = [root '/' triple{3}];
    
    eRecord = PhoneRecord(ePath);
    nRecord = PhoneRecord(nPath);
    zRecord = PhoneRecord(zPath);
    
    threshold = thresholds(i);
    
    combinedRecord = combineShakeTableRecordings( eRecord, nRecord, zRecord, w1, w2, threshold, channel );
    
    % scale the merged record
   
    data = combinedRecord.data;
    nDataPoints = size(data,2);
    
    targetAmplitudes = intendedAmplitudes(i,:);
    
    % peak amplitudes of the recordings:
    peakAmplitudes = max(abs(transpose(data(1:3,:))));
    
    %scaleFactors = targetAmplitudes ./  peakAmplitudes;
    
    %scaling = repmat(scaleFactors', 1, nDataPoints);
    
    %data(1:3,:) = data(1:3,:).*scaling;
    
    combinedRecord.data = data;
    
    % rename the merged record
    name = names{i};
    combinedRecord.fileName = name;

    
    % display, and save figure
    h = combinedRecord.display();
    axis([0,w1+w2, -10, 10])
    
    saveFigure = false;
    if saveFigure
        saveas(h, name, 'fig')
        saveas(h, name, 'png')
    end
    
    % write to .acsn file    
    %combinedRecord.writeToFile(name);
    
    cRecords{i} = combinedRecord;
end


%% This saves segments suitable for making LtSt features.
% Run the previous part once and save cRecordsA, then again for the other
% android files and save cRecordsB. Concatenate and run the rest to
% make segments.

import timeSeries.*

sampleRate = 50; % to match sample rate of other experiments

%cRecordsB = cRecords;
%cRecordsA = cRecords;
%cAndroidShakeRecords = [cRecordsA; cRecordsB];

% extract the time series objects from each of these records

nAndroidShakeRecords = length(cAndroidShakeRecords);
cAndroidShakeSegments = cell(nAndroidShakeRecords,1);

for i=1:nAndroidShakeRecords
    record = cAndroidShakeRecords{i};
    data = record.data;
    Fs = record.sampleRate;
    uTS = UniformTimeSeries(data, Fs,0);
    cAndroidShakeSegments{i} = uTS;
end

save('cAndroidShakeSegments.mat', 'cAndroidShakeSegments');

%% Load the Episensor data

import episensor.*
import file.*
import cell.*

% directory containing the episensor scripts
rootDir = 'data/shakeTable_9-24-2010/20100924_phidgets_BMA_phone_test/';

% you might want these to match the values used above...
w1 = 5; % seconds
w2 = 25; % seconds
threshold = 1; % m/s^2

% get the full path of each script in that directory
[ cScripts, cNames ] = listFiles( rootDir, 'm' );

% loadEpisensorEvent

nRecords = length(cScripts);
cTimeSeries = cell(0,0);

for i=1:nRecords
    script = cScripts{i};
    try
        events = loadEpisensorEvent( script, w1, w2, threshold);
        for j=1:length(events)
            cTimeSeries{end+1} = events{j};
        end
    catch e
        disp(e.message);
    end
    
end

cEpisensorEvents = deleteEmptyCells(cTimeSeries);

%save('cEpiSensorEvents', 'cEpiSensorEvents');

%% Maximize correlation

% cRecords - cell array of PhoneRecord objects
% cEpiSensorEvents - cell array of UniformTimeSeries objects

% for each channel of each PhoneRecord, maximize the correlation between
% the signals. This will require resampling, and shifting in time. The most
% accurate way would be to shift the record of higher sample rate. Will
% also need to do some trimming, because shifted signals are unlikely to
% overlap exactly.

%cEpisensorEvents = cEpisensorEvents(3:end); % <--------- skip the first two, they're sine waves
nEpisensorEvents = length(cEpisensorEvents);
nPhoneRecords = length(cRecords);

maxShift = 1.5; % seconds

% for i=1:nEpisensorEvents 
%    event = cEpisensorEvents{i};
%    figure()
%    plot(event.getTimes(), event.X);
% end

maxCorrelations = zeros(3,nPhoneRecords); % save max correlations of x,y,z channels
for i=1:nPhoneRecords
    phoneRecord = cRecords{i};
   data = phoneRecord.data;
      
   for j = 1:3
      channel = data(j,:);
      % make a timeSeries
      phoneEvent = UniformTimeSeries(channel, phoneRecord.sampleRate, 0);
      
      correlations = zeros(nEpisensorEvents,1);
      for k=1:nEpisensorEvents
         episensorEvent = cEpisensorEvents{k};
         c = maximizeCorrelation(phoneEvent, episensorEvent, maxShift);
         correlations(k) = c;
      end
      maxCorrelations(j,i) = max(correlations);
      
   end

   
end

% % maximum correlations:
% for i=1:nPhoneRecords
%    cor = norm(maxCorrelations(:,i),2);
%    disp(num2str(cor))
% end




%% Plot the inputs (csv) signals

clear all; close all

% its too bad I can't easily match these up with the sac files they came
% from... I should deal with that...
csvFiles = {'1_30.00000s_0.84009g_e.csv', '1_30.00000s_0.86076g_n.csv','1_30.00000s_0.83004g_z.csv';
    '4_30.00000s_0.36346g_e.csv', '4_30.00000s_0.43640g_n.csv', '4_30.00000s_0.15611g_z.csv';
    '5_30.00000s_0.47849g_e.csv', '5_30.00000s_0.61116g_n.csv', '5_30.00000s_0.24508g_z.csv'};

root = 'data/shakeTable_9-24-2010/fridayCsv/';

names = {'1-input', '4-input', '5-input'};

numRecords = size(csvFiles,1);

for i = 1:numRecords;
    
    componentFileNames = csvFiles(i,:);
    ePath = [root componentFileNames{1}];
    nPath = [root componentFileNames{2}];
    zPath = [root componentFileNames{3}];
    
    e = csvread(ePath);
    n = csvread(nPath);
    z = csvread(zPath);
    
    % as shown in the file names, these are each 30 seconds long.
    % Oops. Actually 31 seconds long.
    nPoints = length(e);
    indices = 0:(length(e)-1);
    samplePeriod = 31 / length(e); % 31 seconds long
    t = indices * samplePeriod;
    
    data = zeros(4, nPoints);
    data(1,:) = e' * 9.806; % convert to m/s^2
    data(2,:) = n' * 9.806;
    data(3,:) = z' * 9.806;
    data(4,:) = t;
    
    name = names{i};
    figure()
    plot(t, data(1:3,:))
    title(name)
    xlabel('seconds')
    ylabel('m/s^2')
    
    saveas(gcf, name, 'fig')
    saveas(gcf, name, 'png')
    
end

disp('done')


