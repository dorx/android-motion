% Filter SAC files by distance and magnitude
% 
% Loads some SAC files, and prints the file names of those that satisfy the
% stated conditions
%clear all;

import sac.*


minAmplitude = 0;
maxAmplitude = 10;

minDistance = 0; %km
maxDistance = 40; %km

%

sacRootDir = uigetdir();

% if matlabpool('size')==0
%     try
%         matlabpool open
%     catch exception
%         disp('Exception opening matlab pool')
%         disp(exception)
%     end
% end

profile on
 
cSacRecords = SacLoader.loadSacRecords(sacRootDir);

nRecords = length(cSacRecords);

distances = zeros(nRecords,1);
magnitudes = zeros(nRecords,1);

nAccepted = 0;

for i=1:length(cSacRecords)
    sacRecord = cSacRecords{i};
    d = sacRecord.distanceToEvent();
    m = sacRecord.eventMagnitude();
    
    distances(i) = d;
    magnitudes(i) = m;
    
    if (d < maxDistance) && (m > minAmplitude)
        
        nAccepted = nAccepted + 1;
        
        peak = max(sacRecord.getMagnitude);
        
        % station?
        stationString = sacRecord.eWaveform.header.stations.knetwk;
        
        fprintf(' -------------------------------------\n')
        fprintf('Record %d\n', nAccepted)
        %fprintf('Station data: %s\n', stationString)
        disp(['Station data: ' stationString]);
        fprintf('Distance: %4.2f km\n', d);
        fprintf('Event Magnitude: %2.4f\n', m);
        fprintf('Peak ground acceleration: %2.4f\n', peak);
        
        eFile = sacRecord.eWaveform.fileName;
        nFile = sacRecord.nWaveform.fileName;
        zFile = sacRecord.zWaveform.fileName;
        
        disp(eFile)
        disp(nFile)
        disp(zFile)
        
    end
end

[distances, I] = sort(distances);
magnitudes = magnitudes(I);
clear I;

profile viewer