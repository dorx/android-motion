%% Segment EpiSensor recordings, and save them all

clear all;
close all;

import episensor.*
import file.*
import cell.*

% directory containing the episensor scripts
rootDir = 'data/shakeTable_9-24-2010/20100924_phidgets_BMA_phone_test/';

w1 = 5; % seconds
w2 = 25; % seconds
threshold = 0.01; % m/s^2

% get the full path of each script in that directory
[ cScripts, cNames ] = listFiles( rootDir, 'm' );

% loadEpisensorEvent

nRecords = length(cScripts);
%cTimeSeries = cell(nRecords,1);
cTimeSeries = {};

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



%% Plot an episensor recording
%clear all;
%close all;

import timeSeries.*

% I think these are the records for the 9-24-10 experiments (1,4,5 in my
% notes). Its hard for me to say which is which, since each channel was
% recorded separately. Maybe I should process them all into time series,
% and then test them all against the android recordings!

% Signal 1 (8 m/s2):
% M20100828_080407_KM_KMI.m 

% Signal 4 (4 m/s2):
%M20100828_083515_KM_KMI.m

% Signal 5 (5 m/s2):
% M20100828_084551_KM_KMI.m

rootDir = 'data/shakeTable_9-24-2010/20100924_phidgets_BMA_phone_test/';

[fileName, pathName] = uigetFile(rootDir);

disp(fileName)

fullPath = [rootDir fileName];

loadCommand = ['run ' fullPath];
eval(loadCommand);

% ------------------------------------------------------------------------

% get the data I want, and convert units

% episensor acceleration, converted to m/s^2
episensorData = Ch_3_C3 * 9.8* 4 / (2^23);
episensorData = episensorData -mean(episensorData);

% samples per second:
sps = Ch_3_C3_SPS;

nDataPoints = length(episensorData);
t = (1:nDataPoints) / sps;

% plot

figure()
plot(t, episensorData);
title(fileName)
xlabel('seconds')
ylabel('m/s^2')


%%
% try to get x,y,z channels of one event all on the same plot

for i=1:length(cEpisensorEvents)
    figure()
    plot(cEpisensorEvents{i}.X)
    title(num2str(i))
end

% 1,3, and 8

% 12, 13, 14, maybe 16?

% close all

z = cEpisensorEvents{12};
e = cEpisensorEvents{14};
n = cEpisensorEvents{16};

t = e.getTimes;
figure
plot(t,e.X,t,n.X,t,z.X)
title('Episensor Shake Table Record')
xlabel('seconds')
ylabel('m/s^2')


%%

% make into a timeSeries, and segment:

uTS = UniformTimeSeries(episensorData, sps, 0);

w1 = 5;
w2 = 25;
threshold = 1;
event = uTS.getOnset( w1, w2, threshold);



%%
% plot the event:
t = event.getTimes();
X = event.X;

plot(t,X')

% save the time series, with some meaningful name?


%%





