
%%

% Scratch space

% Android recordings are "raw" in that they are not segmented and aligned;
% the three channels of data are recorded sequentially on one channel; the
% signal may appear more than once in any recording.

import phone.*

% load the data

acsnDir = 'data/shakeTable_9-24-2010/android_B';

cPhoneRecord = PhoneRecord.loadPhoneRecordDir(acsnDir);

nRecords = length(cPhoneRecord);

% plot the data

for i=1:nRecords
    phoneRecord = cPhoneRecord{i};
    %phoneRecord.displayRawData();
    rawData = phoneRecord.rawData;
    
%     x = rawData(1,:);
%     y = rawData(2,:);
%     z = rawData(3,:);
%     
     t = rawData(4,:);
%     
%     figure()
%     plot(t,y)
    
    % Use PCA to extract signal
    
    X = rawData(1:3,:);
    
    mu = mean(X,2);
    sigma = std(X,1,2); % the 1 is to use normalization by N, rather than N-1, to match zscore
    
    % these can be used to normalize data:
    n = size(X,2);%% Use the new functions (make sure they're on the path)

clear all; close all;

import phone.*
import timeSeries.*

% the intended peak amplitude of each recording (as recorded in the file names):
intendedAmplitudes = [0.84009, 0.86076, 0.83004; 0.36346, 0.43640, 0.15611; 0.47849, 0.61116, 0.24508]; % in g
intendedAmplitudes = intendedAmplitudes * 9.806;


% For "Android B", the records are (ls -m is helpful here)
% I've made each row a "triplet"
androidFilesB = ...
    {'1.e.acsn', '1.n.acsn', '1.z.acsn'; '4.e.acsn', '4.n.acsn', '4.z.acsn'; '5.e.acsn', '5.n.acsn', '5.z.acsn'};

%names = {'1A-combined', '4A-combined', '5A-combined'};
%root = 'data/shakeTable_9-24-2010/android_A';

names = {'1B-combined', '4B-combined', '5B-combined'};
root = 'data/shakeTable_9-24-2010/android_B';


w1 = 5; % seconds
w2 = 25; % seconds
thresholds = [2, 1, 1]; % m/s^2
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
    
    scaleFactors = targetAmplitudes ./  peakAmplitudes;
    
    scaling = repmat(scaleFactors', 1, nDataPoints);
    
    data(1:3,:) = data(1:3,:).*scaling;
    
    combinedRecord.data = data;
    
    % rename the merged record
    name = names{i};
    combinedRecord.fileName = name;

    
    % display, and save figure
    %h = combinedRecord.display();
    %saveas(h, name, 'fig')
    %saveas(h, name, 'png')
    
    % write to .acsn file    
    %combinedRecord.writeToFile(name);
    
    cRecords{i} = combinedRecord;
end

%%

% Scratch space

% Android recordings are "raw" in that they are not segmented and aligned;
% the three channels of data are recorded sequentially on one channel; the
% signal may appear more than once in any recording.

import phone.*

% load the data

acsnDir = 'data/shakeTable_9-24-2010/android_B';

cPhoneRecord = PhoneRecord.loadPhoneRecordDir(acsnDir);

nRecords = length(cPhoneRecord);

% plot the data

for i=1:nRecords
    phoneRecord = cPhoneRecord{i};
    %phoneRecord.displayRawData();
    rawData = phoneRecord.rawData;
    
%     x = rawData(1,:);
%     y = rawData(2,:);
%     z = rawData(3,:);
%     
     t = rawData(4,:);
%     
%     figure()
%     plot(t,y)
    
    % Use PCA to extract signal
    
    X = rawData(1:3,:);
    
    mu = mean(X,2);
    sigma = std(X,1,2); % the 1 is to use normalization by N, rather than N-1, to match zscore
    
    % these can be used to normalize data:
    n = size(X,2);
    X = (X - repmat(mu,1,n)) ./ repmat(sigma,1,n);
    
    % princomp requires each data point to be a row
    C = princomp(X');
    
    % princomp assumes data points are rows, so Y is in rows, too.
    Y = X'*C; % <---- check this (seems to check out...)
    
    Y = transpose(Y);
    
    h = figure();
    plot(t,sum(Y,1))
    
    reply = input('Press Enter', 's');
    close(h);
end
    
   
% segment the data and align

% merge the channels into one data structure. 

% maybe write this data structure out as an acsn file?



    X = (X - repmat(mu,1,n)) ./ repmat(sigma,1,n);
    
    % princomp requires each data point to be a row
    C = princomp(X');
    
    % princomp assumes data points are rows, so Y is in rows, too.
    Y = X'*C; % <---- check this (seems to check out...)
    
    Y = transpose(Y);
    
    h = figure();
    plot(t,sum(Y,1))
    
    reply = input('Press Enter', 's');
    close(h);
end
    
   
% segment the data and align

% merge the channels into one data structure. 

% maybe write this data structure out as an acsn file?


%%

% The 9-24 experiment recorded three events, labelled 1,4, and 5. The
% three channels of each event were recorded separately. 

% The input files were:

% 1_30.00000s_0.83004g_z.csv
% 1_30.00000s_0.84009g_e.csv
% 1_30.00000s_0.86076g_n.csv
% 
% 4_30.00000s_0.15611g_z.csv
% 4_30.00000s_0.36346g_e.csv
% 4_30.00000s_0.43640g_n.csv
% 
% 5_30.00000s_0.24508g_z.csv
% 5_30.00000s_0.47849g_e.csv
% 5_30.00000s_0.61116g_n.csv
% 

import phone.*
import timeSeries.*

% the intended peak amplitude of each recording (as recorded in the file names):
intendedAmplitudes = [0.84009, 0.86076, 0.83004, 0.36346, 0.43640, 0.15611, 0.47849, 0.61116, 0.24508];

% For "Android B", the records are (ls -m is helpful here)
androidFilesB = ...
    {'1.e.acsn', '1.n.acsn', '1.z.acsn', '4.e.acsn', '4.n.acsn', '4.z.acsn', '5.e.acsn', '5.n.acsn', '5.z.acsn'};

root = 'data/shakeTable_9-24-2010/android_B';

% load each file, 
% select the one channel of largest signal
% create UniformTimeSeries object
% scale to the intended peak amplitude
% segment out the 30 seconds of signal
%
% display

w1 = 5;
w2 = 25;
threshold = 0.5; % m/s^2

for i=1:length(androidFilesB)
   name = androidFilesB{i};
   path = [root '/' name];
   
   phoneRecord = PhoneRecord(path);
   data = phoneRecord.data(1,:);
   
   % scale data to intended amplitude
   
   % trim off the beginning 
   data = data(:, 100:end);
   
   Fs = phoneRecord.sampleRate;
   
   timeSeries = UniformTimeSeries(data, Fs, 0);
   
   [event, rest] = timeSeries.getOnset(w1, w2, threshold);
   
   figure()
   plot(event.X')
   legend('x', 'y', 'z')
   
end



%% work out the details for combining three acsn files into one. 
% Main issues are segmentation and alignment.

clear all;
close all;

import phone.*
import timeSeries.*

root = 'data/shakeTable_9-24-2010/android_B';

e = '1.e.acsn';
n = '1.n.acsn';
z = '1.z.acsn';



ePeak = 0.84009; % g 
nPeak = 0.86076; % g
zPeak = 0.83004; % g

channel = 1; % which of the records channels recorded the acceleration.

w1 = 5;
w2 = 25;
threshold = 1; % m/s^2

%

ePath = [root '/' e];
nPath = [root '/' n];
zPath = [root '/' z];

eRecord = PhoneRecord(ePath);
nRecord = PhoneRecord(nPath);
zRecord = PhoneRecord(zPath);

% TODO: consider trimming off the first second of data, since it often
% contains noise from placing the phone on the shake table. This noise 
% interferes with automatic segmentation.

eSampleRate = eRecord.sampleRate;
eData = eRecord.data(channel,:);
eTimeSeries = UniformTimeSeries(eData, eSampleRate, 0);
eEvent = eTimeSeries.getOnset(w1, w2, threshold);

nSampleRate = nRecord.sampleRate;
nData = nRecord.data(channel,:);
nTimeSeries = UniformTimeSeries(nData, nSampleRate, 0);
nEvent = nTimeSeries.getOnset(w1, w2, threshold);

zSampleRate = zRecord.sampleRate;
zData = zRecord.data(channel,:);
zTimeSeries = UniformTimeSeries(zData, zSampleRate, 0);
zEvent = zTimeSeries.getOnset(w1, w2, threshold);

% TODO: scale the records to obtain the original peak acceleration.

% figure()
% plot(eEvent.X)
% title('eEvent')
% 
% 
% figure()
% plot(nEvent.X)
% title('nEvent')
% 
% figure()
% plot(zEvent.X)
% title('zEvent')


signalLength = w1+w2; % seconds
desiredSampleRate = eSampleRate; % samples per second
desiredPeriod = 1 / desiredSampleRate;

sampleTimes = transpose(0:desiredPeriod:(signalLength-1));

eSamples = eEvent.interpolatedValues(sampleTimes);
nSamples = nEvent.interpolatedValues(sampleTimes);
zSamples = zEvent.interpolatedValues(sampleTimes);

samples = [eSamples; nSamples; zSamples];

figure()
plot(sampleTimes, samples)
title('reconstructed signal')

% convert to a phone record 
data = [samples; sampleTimes'];

combinedRecord = PhoneRecord('file', eSampleRate, data);

% write to file?

% x = 0.98723487;
% y = 0.2348721394879;
% z = 0.98798798;
% t = 1234897987;
% sprintf('%10.10f %10.10f %10.10f %d\n', x, y, z, t)

combinedRecord.writeToFile('test');

