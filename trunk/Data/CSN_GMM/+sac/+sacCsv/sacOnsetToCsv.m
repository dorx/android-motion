function sacOnsetToCsv( sacRecord, name, w1, w2, threshold )
% sacToCsv - convert a sac file to a CSV file for use with Agilent's
% IntuiLink software. Only extract the onset of the event
%
% Input:
%   sacFile - full path to a SAC file
%   name - name used in csv file name
%   w1 - time before onset to include in the csv file. seconds
%   w2 - time after onset to include in the csv file. seconds
%   threshold - amplitude to detect an onset. m/s^2
%
import sac.*
import sac.sacCsv.*
import check.*
import synthetic.*

%MAX_LENGTH = 64000; % maximum length of Agilent 33220A arbitrary waveforms
MAX_LENGTH = 16000; % maximum length of Agilent 33210A arbitrary waveforms

onset = SegmentSynthesizer.getSacOnsetSegment(sacRecord, w1, w2, threshold);

if isempty(onset)
   disp('no onset detected')
   return
end

A = transpose(onset.X);

% convert from m/s^2 to g
A = A / 9.8;

% make column vectors for each channel, and write each channel to a
% separate CSV file

eAccel = A(:,1);
nAccel = A(:,2);
zAccel = A(:,3);

% ----------------------
 
   
   % plot
   
   eHandle = figure();
   
   plot(eAccel);
   
   ylabel('g')
   title('e channel')

   %
   
   nHandle = figure();
   
   plot(nAccel);
      ylabel('g')
   title('n channel')
   
   %
   
   zHandle = figure();
      
   plot(zAccel);
   xlabel('seconds')
   ylabel('g')
   title('z channel')
   
   
   
   % prompt user for key
   
   
   reply = input('Next: n, Quit: q [n]  ', 's');

   close(eHandle);
       close(nHandle);
       close(zHandle);

% ------------------------

% figure()
% plot(A)
% title(name)

waveformLengthSeconds = onset.lengthSeconds();

fileNameBase = sprintf('%s_%5.5fs', name, waveformLengthSeconds);

writeColumnToCsv(eAccel, fileNameBase, 'e');
writeColumnToCsv(nAccel, fileNameBase, 'n');
writeColumnToCsv(zAccel, fileNameBase, 'z');

end

function writeColumnToCsv(data, fileNameBase, channel)
    import check.*
    
    maxAbs = max(abs(data));
    
    % normalize data to be in [-1.1]
    
    data = 0.99 * data / maxAbs;
    
    fileName = sprintf('%s_%5.5fg_%s.csv', fileNameBase, maxAbs, channel);
    
    assert(isColumnVector(data))
    
    csvwrite(fileName, data);

end
