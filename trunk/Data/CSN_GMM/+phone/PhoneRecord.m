classdef PhoneRecord
    % PhoneRecord - describes an Android acsn file
    %
    % This should depend on PhoneLoader, but PhoneLoader should not depend
    % on this.
    %
    % author: Matt Faulkner
    
    % ===================================================================
    
    properties
        fileName    % name of acsn file
        sampleRate  % average samples per second
        data        % (4xn) matrix. Each column is X,Y,Z,T in m/s^2 and seconds.
                    % Gravity subtraction has been performed.
                    
        %rawData     %(4xn) matrix. Each column is X,Y,Z,T in m/s^2 and seconds.
                    % NO GRAVITY SUBTRACTION
    end
    
    % ===================================================================
    
    methods
        
        % ---------------------------------------------------------------
        
        function obj = PhoneRecord(acsnFile, sampleRate, data)
           % constructor - can be used as a one-argument constructor, that
           % loads a file, or as a three-argument constructor which uses
           % the given data.
           %
           % Input:
           %    acsnFile - path to a .acsn file (in one-argument mode), or
           %        the 'file name' in 3 argument mode
           %    sampleRate - used in 3 argument mode
           %    data - used in 3 argument mode. Each column is an x,y,z,t
           %        data point
           %
           import phone.*
           import check.*
           
           if nargin == 1
               % construct object by loading the acsn file
               assertFile(acsnFile, 'acsn')
               
               [reorientedD, Fs, D] = PhoneLoader.loadAcsnFile(acsnFile);
               
               obj.fileName = acsnFile;
               obj.sampleRate = Fs;
               obj.data = reorientedD;
               
           elseif nargin == 3 
               % construct object with given values
               obj.fileName = acsnFile;
               assert(sampleRate > 0);
               obj.sampleRate = sampleRate;
               assert(size(data,1) == 4); % x,y,z,t
               obj.data = data;
           else
               error('PhoneRecord requires one or three arguments')
           end
           
        end
        
        % ---------------------------------------------------------------
        
        function length = getLength(obj)
            % return the length of the recording, in seconds.
            %
           nSamples = size(obj.data,2);
           length = nSamples / obj.sampleRate;
        end
        
        % ---------------------------------------------------------------
        
        function h = display(obj)
           % plot this PhoneRecord
           h = figure();
           size(obj.data)
           D = obj.data(1:3,:);
           times = obj.data(4,:);
           
           xLabelString = 'seconds';
           
           % if the record is long, scale to minutes?
           if max(times) > 300
               times = times / 60;
               xLabelString = 'minutes';
               duration = times(end) - times(1);
               disp(['Duration: ' num2str(duration) ' minutes']);
           else
               duration = times(end) - times(1);
               disp(['Duration: ' num2str(duration) ' seconds']);
           end
           
           plot(times, D);
           title(obj.fileName);
           xlabel(xLabelString)
           ylabel('m/s^2')
        end
        
        % ---------------------------------------------------------------
        
%         function displayRawData(obj)
%            % plot this PhoneRecord
%            figure()
%            D = obj.rawData(1:3,:);
%            T = obj.rawData(4,:);
%            plot(T,D);
%            title([obj.fileName ' raw Data']);
%            xlabel('seconds')
%            ylabel('m/s^2')
%         end
%         
        % ---------------------------------------------------------------
        
        function writeToFile(obj, name)
           % write data to name.acsn
           %
           % 

           D  = obj.data;
           
           D(4,:) = floor(10^9 * D(4,:)); % convert from seconds to nano seconds
           
           outputName = [name '.acsn'];
           
           nCols = size(D,2);
           
           % open the file with write permission
           fid = fopen(outputName, 'w');
           for i=1:nCols
               sample = D(:,i);
               x = sample(1);
               y = sample(2);
               z = sample(3);
               t = sample(4);
               fprintf(fid, '%10.10f %10.10f %10.10f %d\n', x, y, z, t);
           end
           
           fclose(fid);

        end
        
        % ---------------------------------------------------------------
        
    end
    
    % ===================================================================
    
    methods(Static)
        
        % ---------------------------------------------------------------
        
        function cPhoneRecord = loadPhoneRecordDir(dirName)
            % Load all acsn files in a directory into PhoneRecord objects.
            %
            % Input:
            %   dirName - directory of acsn files
            %
            % Output:
            %   cPhoneRecord - cell array of PhoneRecord objects
            %
            % TODO: this method is computationally heavy, due to gravity
            % subtraction. Might want to change this to also accept a
            % .mat file of cached results.
            %
            import phone.*
            import check.*
            import file.*
            
            assertDirectory(dirName);
            
            
            cFiles = listFiles( dirName, 'acsn');
            nFiles = length(cFiles);
            cPhoneRecord = cell(nFiles,1);
            
            for i=1:nFiles
               file = cFiles{i};
               phoneRecord = PhoneRecord(file);
               cPhoneRecord{i} = phoneRecord;
            end
            
        end
        
        % ---------------------------------------------------------------
        
        
    end
    
    % ===================================================================
    
end

