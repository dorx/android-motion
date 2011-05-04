clear all; % cleans up all variables
close all; % closes all figures
clc; % clean up the command window too


possibleActs = ['walking   ';
                'running   ';
                'sitting   ';
                %'idling    ';
                'upstairs  ';
                'downstairs';
                'biking    '];
possibleActs = cellstr(possibleActs);
possibleUser = ['Alex  ';
                'Daiwei';
                'Doris ';
                'Robert';
                'Wenqi '];
possibleUsers = cellstr(possibleUser);
rootDir = 'C:\Users\AlexFandrianto\Documents\MATLAB\CS141\BackProp\Data';%'C:\Users\Rumpelteazer\Documents\Caltech\AndroidMotion\Data\SensorRecordings\';

user = possibleUsers(2)
%activity = possibleActs(1)

rootDir = 'C:\Users\AlexFandrianto\Documents\MATLAB\CS141\BackProp\Data';

%% Assumes a 3D reduction

for i=1:length(possibleActs)
    act1 = possibleActs(i);
    [XX, YY] = rawTrainingDataOVO(rootDir, user, act1, 'NULL');
    redXX = reduction3(XX);
    C{i} = redXX;
end

plot3(C{1}(:, 1), C{1}(:, 2), C{1}(:, 3), '.r', ...
    C{2}(:, 1), C{2}(:, 2), C{2}(:, 3), '.g', ...
    C{3}(:, 1), C{3}(:, 2), C{3}(:, 3), '.b', ...
    C{4}(:, 1), C{4}(:, 2), C{4}(:, 3), '.c', ...
    C{5}(:, 1), C{5}(:, 2), C{5}(:, 3), '.m', ...
    C{6}(:, 1), C{6}(:, 2), C{6}(:, 3), '.k');
legend(possibleActs)

save('C:/Users/AlexFandrianto/Documents/MATLAB/CS141/BackProp/ReducedData/data_Daiwei_red3.mat', 'C');