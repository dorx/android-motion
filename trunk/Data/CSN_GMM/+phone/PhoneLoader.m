classdef PhoneLoader
    % PhoneLoader. Helper functions for PhoneRecord.
    %
    %
    % author: Matt Faulkner
    %
    
    % ====================================================================
    
    properties (Constant)
        G = 9.88; % m/s^2
    end
    
    % ====================================================================
    
    methods (Static)
        
        % ----------------------------------------------------------------
        
        function [reorientedD, Fs, D] = loadAcsnFile(acsnFile)
            % Load an Android accelerometer file, reorient so Z is "down"
            % and remove gravity.
            %
            % Input:
            %    acsnFile - path to an acsn file
            %
            % Output:
            %    reorientedD - phone data, with gravity removed, in m/s^2 and seconds.
            %       the rows are x,y,z,t.
            %    Fs - average sampling rate
            %    D - phone data prior to reorienting and subtracting
            %       gravity.
            import phone.*
            import check.*
            
            if ~isFile(acsnFile, 'acsn');
                % TODO: this should throw an exception
                error('acsnFile cannot be found or is not an acsn file.')
            end
            
            LOW_PASS_CUTOFF_FREQUENCY = 5; % Hz. Used in finding the direction of gravity.
            
            raw = load(acsnFile);
            
            x = raw(:,1);
            y = raw(:,2);
            z = raw(:,3);
            t = raw(:,4); % in nanoseconds
            t = t * 10^-9; % convert to seconds
            
            nPoints = size(raw,1);
            assert(nPoints ~= 0)

            % TODO: might want to calibrate somehow...
            
            % compute average sample period, and shift to start at t=0
            startT = t(1);
            endT = t(nPoints);
            avgSamplePeriod = (endT - startT) / nPoints;
            
            t = t - startT;

            D = [x , y , z ,t]'; % transpose, to adhere to "column is data point convention"

            % --- reorient and subtract gravity ---
            %disp('Reorienting and subtracting gravity...')
            fSample = 1 / avgSamplePeriod;
            
            fCutoff = LOW_PASS_CUTOFF_FREQUENCY; % in Hz
            
            try
                reorientedAcceleration = PhoneLoader.removeGravityLP(D(1:3,:), fSample, fCutoff);
            catch exception
                disp(exception)
                disp(['Error in removing gravity while loading ' acsnFile]);
                reorientedD = [];
                Fs = 1;
                return
            end
            
            reorientedD = zeros(4, nPoints);
            reorientedD(1:3, :) = reorientedAcceleration;
            reorientedD(4, :) = D(4, :); % t component is unchanged
            
            Fs = fSample;
            
        end
        
        % ----------------------------------------------------------------        
        
        
        
        % ----------------------------------------------------------------
        
        function [cD_reoriented, cFs, cNames, cD] = loadAcsnDir(acsnDir)
            % Load all acsn files in a directory (non-recursive)
            %
            % Input:
            %   acsnDir - path to a directory of acsn files
            %   
            % Output:
            %   cD_reoriented - cell array of matrices.Each column is an x,y,z,t data
            %   point, in m/s^2 and seconds.
            %   cFs - cell array of samples per second
            %   cNames - cell array of loaded files' names
            %   cD - cell array of matrices. Data without gravity
            %   subtraction.
            %
            % NOTE: this is becoming obsolete
            %
            import phone.*
            import check.*
            
            if ~isDirectory(acsnDir)
                error([acsnDir ' cannot be found or is not a directory.'])
            end
            
            % get the names of all files. dirListing is a struct array.
            dirListing = dir(acsnDir);
            
            
            cD_reoriented = cell(length(dirListing),1);
            cFs = cell(length(dirListing),1);
            cNames = cell(length(dirListing),1);
            cD = cell(length(dirListing),1);
            
            % loop through the files and open. dir also lists the
            % directories, so you have to check for them.
            %
            % TODO: might want to use file.listFiles
            %
            for d = 1:length(dirListing)
                if ~dirListing(d).isdir
                    fileName = fullfile(acsnDir,dirListing(d).name); % use full path because the folder may not be the active path
                    
                    if isFile(fileName, 'acsn')
                        disp(fileName)
                        [D_reoriented, Fs, D] = PhoneLoader.loadAcsnFile(fileName);
                        
                        % this may not be necessary. Was introduced because
                        % some acsn files crashed the PhoneRecord gravity
                        % subtraction
                        
                        if isempty(D_reoriented)
                            continue
                        end
                        
                        cD_reoriented{d} = D_reoriented;
                        cFs{d} = Fs;
                        cNames{d} = dirListing(d).name;
                        cD{d} = D;
                    end
                end
            end
            
            %Remove empty cells, e.g. listings that were directories and skipped over.
            cD_reoriented(cellfun(@isempty,cD_reoriented)) = [];
            cFs(cellfun(@isempty,cFs)) = [];
            cNames(cellfun(@isempty, cNames)) = [];
            
        end
        
        % ----------------------------------------------------------------
        
        function [correctedD, lpD] = removeGravityLP(D, fSample, fCutoff)
            % REMOVE_GRAVITY_LP Removes acceleration due to gravity A low pass of the data
            % gives a smoothly varying estimate of 'down'. The data is then rotated; it
            % is not filtered.
            %
            % Input:
            %   D - 3xn data matrix, in m/s^2. Each column is a 3-dimensional data point.
            %   sampleRate - sample rate of input data (Hz)
            %   fCutoff - cutoff frequency (Hz) for lowpass filter (0.25 looks like an
            %       okay value).
            %
            % Output:
            %   correctedD - data, rotated so gravity is down, with gravity subtracted.
            %   lpD - low pass filtered data.
            %
            
            [d,n] = size(D);
            assert(d==3); % need 3-dimensional data points
            assert(fSample > 0)
            assert(fCutoff > 0)
            
            % normalized to between 0 and 1. The 2 is for the Nyquist rate.
            % If it is not in (0,1), an error results...
            %
            fNorm = fCutoff / (fSample / 2); 
            [B,A] = butter(5, fNorm, 'low'); % B,A are filter coefficients
            
            
            %The length of the input x must be more than three times
            %the filter order, defined as max(length(b)-1,length(a)-1)
            lpD = zeros(size(D));
            for i=1:3
                lpD(i,:) = filtfilt(B,A, D(i,:));
            end
            
            %fprintf('            If a message, ''Matrix is close to singular or badly scaled,'' appears,\n');
            %fprintf('            then Matlab has failed to design a good filter. \n');
            %fprintf('            This could mean the butterworth filter is too sharp. \n');
            %
            % use the low passed values as estimates of gravity. Rotate each original
            % data point so that its lp value is down.
            rotatedD = zeros(size(D));
            parfor i = 1:n
                lp = lpD(:,i);
                r = vrrotvec(lp, [0,0,-1]); %get rotation in axis-angle form.
                %I don't know if I need to scale [0,0,-1]
                %to have the same mag as lp
                R = vrrotvec2mat(r); %convert to a rotation matrix
                rotatedD(:,i) = R*D(:,i);
            end
            
            % add one G to the z component
            correctedD = rotatedD;
            correctedD(3,:) = correctedD(3,:) +  9.88;
            
        end
        % ----------------------------------------------------------------
        
        % ----------------------------------------------------------------
        
        
    end
    
    % ====================================================================
    
end


% Some notes on Matlab's filtering (Related to gravity subtraction)

% from http://www.aquaphoenix.com/lecture/matlab10/page4.html
%
% Matlab includes function butter  for building Butterworth filters of three sorts:
% 
%     * 'low' : Low-pass filters, which remove frequencies greater than some specified value.
%     * 'high' : High-pass filters, which remove frequencies lower than some specified value.
%     * 'stop' : Stop-band filters, which remove frequencies in a given range of values. 
% 
% Frequencies values are specified in normalized terms between 0.0 and 1.0,
% where 1.0 corresponds to half the sampling frequency: f/2. A given 
% frequency is thus expressed in terms of this value, for example, 1000Hz = 1000/(f/2).
% 
% Filters are described in terms of 2 vectors ([b, a] = [numerator, denominator]).
% 
% To apply a filter to a 1-D audio waveform, Matlab provides function 
% filtfilt , which takes as arguments the result [b, a] from butter, the 
% waveform, and a value denoting the order (number of coefficients) of the 
% filter.
% 
% A filter's frequency response can be plotted using function freqz . 
% Magnitude values at zero dB are unaffected by the filter. Magnitude 
% values below 0 dB are suppressed. 

