function [ output_args ] = viewPhoneWaveforms( rootDir )
% viewPhoneWaveforms - open a directory of acsn files, and view plots one at a
% time.
%
% Input: 
%   rootDir - directory containing acsn files. Optional
%
% n - view next
% q - quit


import phone.*
import check.*

if nargin == 0
    rootDir = uigetdir();
end

cPhoneRecords = PhoneRecord.loadPhoneRecordDir(rootDir);





for i=1:length(cPhoneRecords)
   phoneRecord = cPhoneRecords{i};
   
   disp('')
   
   % plot
   
   h = phoneRecord.display();
   
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

