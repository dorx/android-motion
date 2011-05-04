function [redudata] = multi_act_reduction1()

%{ 
FILE: multi_act_reduction1.m

USE: This script create 6 matrices containing reduced/pruned data for 6 
     activities. The matrices are stored in "redudata", where redudata{1}
     is the matrix for the first activity. 


PARAMETERS:
    filename: A file containing all file names. The file need to be in 
              specific format: for each activity, first line is comment,
              second line is # of files, and the rest is file names.
    nact = 6 : number of activities. 
    reduction2 : reduction scheme. (Later in the code. See comments.)
%}

filename = 'SensorRecordings/log_Daiwei_allact.dat';
dir = 'SensorRecordings/';

% 6 activities: biking, downstairs, idle, running, upstairs, walking
nact = 6;


%%% Code starts here:

fid = fopen(filename);

% An 1D array
redudata = cell(1, nact);

for i = 1 : nact,

    % First line is comment
    textscan(fid, '%*s', 1, 'delimiter', '\n');
    
    % Second line is number of files.
    nfile = textscan(fid, '%d', 1, 'delimiter', '\n');
    nfile = nfile{1};
    
    % There are nfile filenames
    filenames = textscan(fid, '%s', nfile, 'delimiter', '\n');
    
    % Open all files
    iact  = [];   % Will store all data of activity i 
    for ifile = 1 : nfile,
        fname = strcat(dir,  filenames{1}(ifile));
        ldata = load(fname{1});
        
        %%%%%%%%%%%%%%% CHANGE REDUCTION SCHEME HERE %%%%%%%%%%%%%%%%%%%%
        result = reduction2(ldata);
        
        iact = vertcat(iact, result);
    end
    redudata{i} = iact;
end


fclose(fid);
end
