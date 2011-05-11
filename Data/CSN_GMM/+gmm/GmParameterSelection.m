classdef GmParameterSelection
    % GmParameterSelection - evaluate model and feature parameters
    %   
    % author: Matt Faulkner
    %
    
    % ====================================================================
    
    properties
    end
    
    % ====================================================================
    
    methods(Static)
        
        % ----------------------------------------------------------------
        
        function [AUC cTP cFP cParams models] = evaluateParameters(data, parameters)
            % evaluateParameters - compute AUC (area under ROC curve), TP
            % (true positive rate) and FP (false positive rate) for each
            % combination of parameters.
            %
            % Input:
            %   data - struct with the followin fields:
            %       rootDir - path to the 'Picking' directory
            %       phoneTrainingDir - relative path from Picking to a
            %           directory of acsn files.
            %       phoneTestingDir - relative path from Picking to a
            %           directory of acsn files.
            %       sacRootDir - relative path from Picking to a directory
            %           containing directories named 'e', 'n', and 'z'.
            %           These each contain files of one channel of sac
            %           data.
            %
            %   parameters - struct with the following fields:
            %       NumGaussians - vector. model parameter.
            %       NumFrequencyCoefficienst - vector. Feature parameter.
            %       NumMoments - vector. Feature parameter
            %       DimensionsRetained  - vector.
            %       segmentLength - scalar. Length of segments for
            %           features.
            %       sampleRate - scalar. all data is converted to this sample rate.
            %       threshold - amplitude to detect onset. m/s^2
            %       peakAmplitude - scalar. SAC files are scaled to have
            %          this peak amplitude. m/s^2
            %
            
            % Path to the directory Picking, with trailing slash
            rootDir = data.rootDir;
            phoneTrainingDir = data.phoneTrainingDir;
            phoneTestingDir = data.phoneTestingDir;
            sacRootDir = data.sacRootDir;
%             
            NumGaussians = parameters.NumGaussians;
            NumFrequencyCoefficients = parameters.NumFrequencyCoefficients;
            NumMoments= parameters.NumMoments;
            DimensionsRetained = parameters.DimensionsRetained;
            segmentLength = parameters.segmentLength;
    
            sampleRate = parameters.sampleRate;
            
            threshold = parameters.threshold;
            
            peakAmplitude= parameters.peakAmplitude;
            
            import check.*
            import feature.*
            import phone.*
            import sac.*
            import gmm.*
            import synthetic.*
            import parallel.*
            import roc.*
            %
            
            if matlabpool('size')==0
                try
                    matlabpool open
                catch exception
                    disp('Exception opening matlab pool')
                end
            end
            
            % -------------------------------------------------------------
            % combine relatives path with root path.
            
            phoneTrainingDir = [rootDir phoneTrainingDir];
            assertDirectory(phoneTrainingDir);
            
            phoneTestingDir = [rootDir phoneTestingDir];
            assertDirectory(phoneTestingDir);
            
            sacRootDir = [rootDir sacRootDir];
            assertDirectory(sacRootDir);
            
            % -------------------------------------------------------------
            
            loadCachedRecords = false;
            
            if loadCachedRecords
                load('*cache/testingPhoneRecords.mat');
                load('*cache/trainingPhoneRecords.mat');
            else
                % load records from file
                disp(['Loading phone data... ' datestr(now, 'yyyy-mm-dd HH:MM:SS PM')])
                
                cTrainingPhoneRecords = PhoneRecord.loadPhoneRecordDir(phoneTrainingDir);
                cTestingPhoneRecords = PhoneRecord.loadPhoneRecordDir(phoneTestingDir);
                
                disp(['Done loading phone data. '  datestr(now, 'yyyy-mm-dd HH:MM:SS PM')] )

%             disp('Saving phone data to file...')
%             save('*cache/trainingPhoneRecords.mat', 'cTrainingPhoneRecords' );
%             save('*cache/testingPhoneRecords.mat', 'cTestingPhoneRecords' );
%             disp('Done saving.')
     
            end
            
            % -------------------------------------------------------------
            
            loadCachedSegments = false;
            saveNewSegments = false;
            
            if loadCachedSegments
%                 disp('Loading cached segments')
%                 load('*cache/Oct17/trainingSegments');
%                 load('*cache/Oct17/testingNormalSegments.mat');
                
                
                % Oct24: 2.5s short-term, 5s long-term, 1 "dead" 16-bit
                % Phidget data.
                load('*cache/Oct25/phidgetTrainingSegments_ltst.mat');
                cTrainingSegments = cPhidgetTrainingSegments;
                clear cPhidgetTrainingSegments;
                
                load('*cache/Oct25/phidgetTestingSegments_ltst.mat');
                cTestingNormalSegments = cPhidgetTestingSegments;
                clear cPhidgetTestingSegments;
                
                
            else
                % compute segments
                disp(['Segmenting phone data... '  datestr(now, 'yyyy-mm-dd HH:MM:SS PM') ])
                
                cTrainingSegments = GmParameterSelection.segmentPhoneRecords(cTrainingPhoneRecords, segmentLength, sampleRate);
                cTestingNormalSegments = GmParameterSelection.segmentPhoneRecords(cTestingPhoneRecords, segmentLength, sampleRate);
                
                disp(['Done segmenting phone data. ' datestr(now, 'yyyy-mm-dd HH:MM:SS PM')])
                
                %             disp('Saving segments...')
                %             save('*cache/trainingSegments.mat', 'cTrainingSegments');
                %             save('*cache/testingNormalSegments.mat', 'cTestingNormalSegments');
                %             save('*cache/parameters.mat', 'segmentLength', 'sampleRate', 'phoneTrainingDir', 'phoneTestingDir');
                %             disp('Done saving.')
                
            end

            % clear variables that are no longer used:
            clear cTrainingPhoneRecords
            clear cTestingPhoneRecords

            
            
            cSacRecords = SacLoader.loadSacRecords(sacRootDir);
            
            %  ----------Subsample the phone segments. --------------------
            % If the data
            % set of segments is too large, Matlab will be unable to
            % serialize (not enough memory?) and will not be able to use
            % parfor.

            maxTrainingSegments = 10000;
            maxTestingSegments = 10000;
            
            numTotalTrainingSegments = length(cTrainingSegments);
            numTotalTestingSegments = length(cTestingNormalSegments);
            
            
            trainingIndicesSubset = random.randomSubset(numTotalTrainingSegments, maxTrainingSegments);
            testingIndicesSubset = random.randomSubset(numTotalTestingSegments, maxTestingSegments);
            
            %
            cTrainingSegments = cTrainingSegments(trainingIndicesSubset);
            cTestingNormalSegments = cTestingNormalSegments(testingIndicesSubset);
            
            % LOOK: I'm switching them:
            temp = cTrainingSegments;
            cTrainingSegments = cTestingNormalSegments;
            cTestingNormalSegments = temp;
            clear temp;
            % -------------------------------------------------------------
            
            
            disp('Creating synthetic segments')
            cSyntheticSegments= ...
                SegmentSynthesizer.createSyntheticSegments(cTestingNormalSegments, cSacRecords, ...
                segmentLength, sampleRate, threshold, peakAmplitude);
            disp('Done synthesizing')
            
            
            % store parameter combinations in structs, and put them in a cell array
            % loop over parameters
            
            A = length(NumFrequencyCoefficients);
            B = length(NumMoments);
            C = length(DimensionsRetained);
            D = length(NumGaussians);
            
            nParameters =A*B*C*D;
            ranges = [A,B,C,D];
            
            % load parameters into a cell array, for convenient indexing within a
            % parfor loop.
            cParams = cell(nParameters,1);
            for i=1:nParameters
                I = parforIndices(ranges,i);
                
                a=I(1);
                b=I(2);
                c=I(3);
                d=I(4);
                
                params.numFrequencyCoefficients = NumFrequencyCoefficients(a);
                params.numMoments = NumMoments(b);
                params.dimensionsRetained = DimensionsRetained(c);
                params.numGaussians = NumGaussians(d);
                
                
                cParams{i} = params;
            end
            
            disp('Loop over all parameter combinations')

            AUC = zeros(nParameters,1);
            cTP = cell(nParameters,1);
            cFP = cell(nParameters,1);
            models = cell(nParameters,1);

            parfor i=1:nParameters
                
                % unpack parameters
                params = cParams{i};
                nFFT = params.numFrequencyCoefficients;
                nMoms = params.numMoments;
                nGaussians = params.numGaussians;
                dimensionsRetained = params.dimensionsRetained;
                
                [cTrainingFeatures, C, mu, sigma ]= ...
                    GmParameterSelection.computeTrainingFeatures(cTrainingSegments, nFFT, nMoms, nFFT, nMoms, dimensionsRetained, 2); % 2 is the "normal label"
                
                cTestingFeatures = ...
                    GmParameterSelection.computeTestingFeatures(cTestingNormalSegments, cSyntheticSegments, nFFT, nMoms, nFFT, nMoms, C, mu, sigma, dimensionsRetained);
                
                % learn GMM
                gm = GaussianMixture.learnGaussianMixture(cTrainingFeatures, nGaussians, 1); % <=== Magic Number
                
                % evaluate training data
                P = gm.evaluateProbability(cTestingFeatures);
                
                TrueLabels = Feature.unpackLabels(cTestingFeatures);

                Assignments = -log(P);
                
                % a low hack to deal with the infinite!
                infIndices = (Assignments == inf);
                Assignments(infIndices) = 1000;
                nThresh = 1000;
                
                Thresholds = linspace(min(Assignments), max(Assignments), nThresh);
                
                [tp, fp] =  myROC( TrueLabels, Assignments, Thresholds );
                areaUnderCurve = auc(fp,tp);
                %disp(num2str(areaUnderCurve))
                AUC(i) = areaUnderCurve;
                cTP{i} = tp;
                cFP{i} = fp;
                models{i} = gm;
            end
            
            % display best parameters and values.
%             disp('Done');
%             
%             
%             [maxAUC, I] = max(AUC);
%             
%             bestParams = cParams{I};
%             disp(bestParams)
%             
%             % ROC of best parameter setting
%             figure()
%             plot(cFP{I}, cTP{I})
%             title(['ROC. area = ' num2str(maxAUC)])
%             xlabel('False Positive Rate')
%             ylabel('True Positive Rate')

        end
        
        % ----------------------------------------------------------------
        
        function cSegments = segmentPhoneRecords(cPhoneRecords, segmentLength, sampleRate)
            %
            % Input: 
            %   cPhoneRecords - cell array of PhoneRecord objects. Vector
            %   segmentLength - 
            %   sampleRate - segments will be converted to this sample
            %       rate, in samples per second
            %   
            % Output;
            %   cSegments - cell array of TimeSeries objects.
            %
            import synthetic.*
            import phone.*
            import timeSeries.*
            import cell.*
            
            nPhoneRecords = length(cPhoneRecords);
            
            %cSegments = cell(nPhoneRecords,1);
            cSegments = {};
            
            for i=1:nPhoneRecords
                phoneRecord = cPhoneRecords{i};
                cNewSegments = SegmentSynthesizer.segmentPhoneRecord(phoneRecord, segmentLength, sampleRate);
                %cSegments{i} = cNewSegments;
                cSegments = [cSegments; cNewSegments];
            end
            
            %cSegments = cell.cellFlatten(cSegments);
        end
        
        % ----------------------------------------------------------------
        
        function [cFeatures, C, mu, sigma] = computeTrainingFeatures(cTrainingSegments, nFreqZ, nMomZ, nFreqXY, nMomXY, dimensionsRetained, label)
            % compute base features
            % compute PCA parameters
            % apply PCA parameters to compute PcaFeatures
            % return features and PCA parameters
            %
            import gmm.*
            import feature.*
            
            cBaseFeatures = GmParameterSelection.computeBaseFeature(cTrainingSegments, nFreqZ, nMomZ, nFreqXY, nMomXY, label);
            
            [C, mu, sigma] = PcaFeature.computePcaParameters(cBaseFeatures);
            
            cFeatures = GmParameterSelection.computePcaFeatures(cBaseFeatures, C, mu, sigma, dimensionsRetained);
            
        end
        
        % ----------------------------------------------------------------
        
        function cFeatures = computeTestingFeatures(cNormalSegments, cAnomalySegments, nFreqZ, nMomZ, nFreqXY, nMomXY, C, mu, sigma, dimensionsRetained)
           % compute base normal features
           % compute base anomaly features
           % concatenate cell arrays
           % compute PCA features
           %
           import gmm.*
           import feature.*
           
           cNormalBaseFeatures = GmParameterSelection.computeBaseFeature(cNormalSegments,nFreqZ, nMomZ, nFreqXY, nMomXY, 2); % 2 is label of normal data
           cAnomalyBaseFeatures = GmParameterSelection.computeBaseFeature(cAnomalySegments,nFreqZ, nMomZ, nFreqXY, nMomXY, 1); % 1 is label for anomaly data
           
           cBaseFeatures = [cNormalBaseFeatures; cAnomalyBaseFeatures];
           
           % check the labels
           labels = Feature.unpackLabels(cBaseFeatures);
           
           nNormal = length(cNormalBaseFeatures);
           nAnomaly = length(cAnomalyBaseFeatures);
           
           expectedLabels = [2*ones(nNormal,1); 1*ones(nAnomaly,1)];
           
           if any(labels ~= expectedLabels)
              error('computeTestingFeatures: wrong labels') 
           end
           
           cFeatures = GmParameterSelection.computePcaFeatures(cBaseFeatures, C, mu, sigma, dimensionsRetained);
           
        end
        
        % ----------------------------------------------------------------
        
        function cFeatures = computeBaseFeature(cSegments, nFreqZ, nMomZ, nFreqXY, nMomXY, label)
            %
            %
            import gmm.*
            import feature.*
            
            nSegments = length(cSegments);
            
            cFeatures = cell(nSegments,1);
            
            for segIndex =1:nSegments
                segment = cSegments{segIndex};
                xyzFeature = XyzFeature(segment, nFreqZ, nMomZ, nFreqXY, nMomXY, label);
                cFeatures{segIndex} = xyzFeature;
            end
            
            L = Feature.unpackLabels(cFeatures);
            if  any(L ~= label*ones(nSegments,1))
                error('wrong labels!')
            end
        end
        
        % ----------------------------------------------------------------
        
        function cFeatures = computePcaFeatures(cBaseFeatures, C, mu, sigma, dimensionsRetained)
            %
            %
            import gmm.*
            import feature.*
            
            nBaseFeaures = length(cBaseFeatures);
            
            cFeatures = cell(nBaseFeaures,1);
            
            for f=1:nBaseFeaures
                baseFeature = cBaseFeatures{f};
                pcaFeature = PcaFeature(baseFeature.featureVector, C, mu, sigma, dimensionsRetained, baseFeature.getLabel());
                cFeatures{f} = pcaFeature;
            end
            
            baseLabels = Feature.unpackLabels(cBaseFeatures);
            labels = Feature.unpackLabels(cFeatures);
            
            if any(labels ~= baseLabels)
               error('PCA labels do not match base labels') 
            end
        end
        
        % ----------------------------------------------------------------
        
    end
    
    % ====================================================================
    
end

