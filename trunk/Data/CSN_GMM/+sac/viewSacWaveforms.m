function [ output_args ] = viewSacWaveforms( rootDir )
% viewSacWaveforms - open a directory of SAC files, and view plots one at a
% time.
%
% Input: 
%   rootDir - directory containing directories 'e', 'n', and 'z' of SAC files. Optional
%
% n - view next
% q - quit

   
import sac.*
import check.*

if nargin == 0
    rootDir = uigetdir();
end


cSacRecords = SacLoader.loadSacRecords(rootDir);

for i=1:length(cSacRecords)
   sacRecord = cSacRecords{i};
   
   disp('')
   
   peakAmplitude = max(sacRecord.getMagnitude());
   disp(['peak amplitude: ' num2str(peakAmplitude)])
   
   
   distanceToEvent = sacRecord.distanceToEvent();
   disp(['Distance to epicenter: ', num2str(distanceToEvent)])
   
   eWaveform = sacRecord.eWaveform;
   disp(eWaveform.fileName)
   
   nWaveform = sacRecord.nWaveform;
   disp(nWaveform.fileName)
   
   zWaveform = sacRecord.zWaveform;
   disp(zWaveform.fileName)
   
   % plot
   
   
   
   %eHandle = figure();
   eTimes = eWaveform.getTimeSeries.getTimes; % in seconds
   eAccel = eWaveform.accel;
   
   figure('units','normalized','outerposition',[0 0 1 1])
   
   subplot(2,2,1)
   plot(eTimes, eAccel);
   xlabel('seconds')
   ylabel('m/s^2')
   title('e channel')

   %
   
   %nHandle = figure();
   nTimes = nWaveform.getTimeSeries.getTimes; % in seconds
   nAccel = nWaveform.accel;
   
   subplot(2,2,2);
   plot(nTimes, nAccel);
   xlabel('seconds')
   ylabel('m/s^2')
   title('n channel')
   
   %
   
   %zHandle = figure();
   zTimes = zWaveform.getTimeSeries.getTimes; % in seconds
   zAccel = zWaveform.accel;
   
   subplot(2,2,3)
   plot(zTimes, zAccel);
   xlabel('seconds')
   ylabel('m/s^2')
   title('z channel')
   
   
   
   % prompt user for key
   
   
   reply = input('Next: n, Quit: q [n]  ', 's');
   if isempty(reply)
       reply = 'n';
   end
   
   if strcmp(reply, 'n')
       close(gcf)
%        close(eHandle);
%        close(nHandle);
%        close(zHandle);
       continue
   elseif strcmp(reply, 'q')
       break
   end
   
   
   
end

end

