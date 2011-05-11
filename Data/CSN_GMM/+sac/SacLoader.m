classdef SacLoader
    % SacLoader - load a SAC file or directory of files.
    %   Load files, convert to standard units.
    %
    % See http://geophysics.eas.gatech.edu/classes/SAC/ for SAC info
    %
    % author: Matt Faulkner
    %
    
    % ===================================================================
    
    properties(Constant)
        
       %DISPLAY_WARNINGS = false; 
       
    end
    
    % ===================================================================
    
    methods (Static)
        
        % ---------------------------------------------------------------
        
        function [acceleration, Fs, sacHeader, rawData] = loadSacFile(sacFile)
            % Input:
            %   sacFile - path to a SAC file
            %
            % Output:
            %   accel - column vector. Acceeration time series
            %   Fs - samples per second
            %   sacHeader
            %
            %
            import sac.*
            import check.*
            
            % 
%             if ~isFile(sacFile, 'sac')
%                 error([sacFile ' cannot be found or is not a sac file.'])
%             end
            
            %
            
            [~,data,sacHeader] = matsac.fget_sac(sacFile);
            rawData = data;
            
            sacSamplePeriod = sacHeader.times.delta;
            
            % WARNING: Default for SAC is nm/s^2, but data from STP is cm/s^2. 
            % Its unclear if this alternate convention applies only to
            % files created using STP's sac command, or to all data
            % obtained through STP. See the STP manual
            %
            % Also, the SoCal data might be in counts for 24bit sensors
            %
            % Convert to m/s^2
            %SAC_ACCEL_CONVERSION_FACTOR = 10^-9;
            
            % convert from counts to g, then to m/s^2
            %
            % See 
            % http://www.data.scec.org/cgi-bin/stationdb/dig_responselist.cgi
            % for a list of conversion factors for different seismic
            % stations. 
            
            SAC_ACCEL_CONVERSION_FACTOR = (4 / 2^23) * 9.8; % aka 2139 counts per cm/s^2
            
            acceleration = data * SAC_ACCEL_CONVERSION_FACTOR;
            
            % probably want to make the signal zero-mean:
            acceleration = acceleration - mean(acceleration);
            
            Fs = floor(1/sacSamplePeriod);
        end
        
        % ---------------------------------------------------------------
        
        function [cAccel, cFs, cNames] = loadSacDir(sacDir, minAmplitude)
            % Load all sca files in a directory (non-recursive)
            % Input:
            %   sacDir - path to a directory of SAC files
            %   minAmplitude - (m/s^2) Optional. Signals below this
            %       amplitude will be filtered out.
            %   
            % Output:
            %   cAccel - cell array of column vectors. Acceeration time
            %       series in m/s^2
            %   cFs - cell array of samples per second
            %   cNames - cell array of accepted files' names
            %   
            import sac.*
            import check.*
                        
            assertDirectory(sacDir);
            
            if nargin == 1
                minAmplitude = 0;
            end
            
            % get the names of all files. dirListing is a struct array.
            dirListing = dir(sacDir);
            
            cD = cell(length(dirListing),1);
            cFs = cell(length(dirListing),1);
            cNames = cell(length(dirListing),1);
            
            % loop through the files and open. dir also lists the
            % directories, so you have to check for them.
            parfor d = 1:length(dirListing)
                if ~dirListing(d).isdir
                    fileName = fullfile(sacDir,dirListing(d).name); % use full path because the folder may not be the active path
                    
                    if isFile(fileName, 'sac')
                        [accel, Fs] = SacLoader.loadSacFile(fileName);
                        cD{d} = accel;
                        cFs{d} = Fs;
                        cNames{d} = dirListing(d).name;
                    end
                end
            end
            
            %Remove empty cells, e.g. listings that were directories and skipped over.
            cD(cellfun(@isempty,cD)) = [];
            cFs(cellfun(@isempty,cFs)) = [];
            cNames(cellfun(@isempty, cNames)) = [];
            
            % filter out small magnitude events
            fhandle = @(d) max(abs(d));
            acceptIndices = (cellfun(fhandle, cD) >= minAmplitude);
            
            % yes, sometimes you need parens to index into cell arrays...
            cAccel = cD(acceptIndices);
            cFs = cFs(acceptIndices);
            cNames = cNames(acceptIndices);
            
        end
            
        % ---------------------------------------------------------------
        
        % getSacTimeSeries
        % if input is a sac file, load it.
        % if input is a directory, load all sac files in it
        
        % ---------------------------------------------------------------
        
        function cSacRecords = loadSacRecords(rootDir)
            % load SAC records (X,Y,and Z files)
            % 
            % Input:
            %   rootDir - directory containing three sub-directories, named
            %       'e', 'n', and 'z'
            %
            % Output:
            %   cSacRecords - cell array of SacRecord objects
            %
            import sac.*
            import check.*
            import file.*
            import java.lang.String
            
            assertDirectory(rootDir);
            
            % java. Ensure a trailing slash
            rootDirString = String(rootDir);
            rootDirString = rootDirString.trim();
            if ~rootDirString.endsWith('/')
                rootDirString = rootDirString.concat(String('/'));
            end
            rootDir = char(rootDirString);

            zDirectory = [rootDir 'z/'];
            nDirectory = [rootDir 'n/'];
            eDirectory = [rootDir 'e/'];
            
            % check for needed directories
            assertDirectory(zDirectory);
            assertDirectory(nDirectory);
            assertDirectory(eDirectory);
            
            % Get the z file list
            
            [~, cZNames] = listFiles(zDirectory, 'z.sac');
            
            cSacRecords = cell(length(cZNames), 1);
            
            parfor i=1:length(cZNames)
               zFileName = cZNames{i}; % just the name, not the path
               
               % java
               zFileString = String(zFileName);
               if ~zFileString.toLowerCase().endsWith('z.sac')
                   error('wtf?')
               end
               
               nameLength = length(zFileName);
               endingLength = length('z.sac');
               nameRoot = zFileName(1:nameLength-endingLength);
               
               % these names might be incorrectly capitalized...
               nFileName = [nameRoot 'n.sac'];
               eFileName = [nameRoot 'e.sac'];
               
               
               % find correctly capitalized file name
               [containsNFile, trueNFileName] = ...
                   containsFile(nDirectory, nFileName);
               
               if ~containsNFile 
                   %warning([nFileName ' cannot be found in ' nDirectory ]);
                   continue
               end
               
               [containsEFile, trueEFileName] = ...
                   containsFile(eDirectory, eFileName);
               
               if ~containsEFile 
                   %warning([eFileName 'cannot be found in ' eDirectory ]);
                   continue
               end
               
               % load up the files
               zPath = [zDirectory zFileName];
               nPath = [nDirectory trueNFileName];
               ePath = [eDirectory trueEFileName];
               
               try
                   sacRecord = SacRecord(ePath, nPath, zPath);
                   cSacRecords{i} = sacRecord;
               catch e
                   disp(e.message)
               end
            end
            
            % remove empty cells, e.g. Z files that did not have matching N
            % and E files
            cSacRecords(cellfun(@isempty,cSacRecords)) = [];
            
            nRecords = length(cSacRecords);
            sprintf('%d SAC records retained', nRecords)
            
        end
        
        % ---------------------------------------------------------------
        
        
        % ---------------------------------------------------------------
  
    end
    
    % ===================================================================
    
end

