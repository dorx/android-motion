classdef GmLtStParameterSelection
    % GmLtStParameterSelection - evaluate model and Short-term,Long-temr feature parameters
    %
    % author: Matt Faulkner
    %
    % TODO: this has a lot of common machinery with GmParameterSelection.
    % Common functionality should be moved to a super class.
    %
    % ====================================================================
    
    properties
    end
    
    % ====================================================================
    
    methods(Static)
        
        % ----------------------------------------------------------------
        
        function [AUC cTP cFP cParams models cThresholds] = evaluateParameters(data, parameters)
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
            %
            %       --The frequency and moment terms are currently set to
            %         be the same for both short-term and long-term buffers:
            %       NumFrequencyCoefficienst - vector. Feature parameter.
            %       NumMoments - vector. Feature parameter
            %
            %       DimensionsRetained  - vector. PCA dimension reduction.
            %
            %       -- Might want to require t0 to be an integer multiple
            %         of t1, so that I can subsample the frequency
            %         coefficients of the LT
            %       ltLength - length of long-term (lead-in) segment. Scalar.
            %       stLength - length of short-term (recent) segment. Scalar.
            %
            %       threshold - threshold, after scaling, to detect onset.
            %           m/s^2. Scalar
            %       sampleRate - scalar. all data is converted to this sample rate.
            %       peakAmplitude - scalar. SAC data is scaled by this amount prior
            %           to creation of synthetic data.
            %
            import check.*
            import feature.*
            import phone.*
            import sac.*
            import gmm.*
            import synthetic.*
            import parallel.*
            import roc.*
            
            
            if matlabpool('size')==0
                try
                    matlabpool open
                catch exception
                    disp('Exception opening matlab pool')
                    disp(exception)
                end
            end
            
            
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
            
            ltLength = parameters.ltLength;
            stLength = parameters.stLength;
            
            deadTime = 1; % seconds of "dead time" between short term and long term buffers
            
            segmentLength = ltLength + stLength + deadTime;
            
            sampleRate = parameters.sampleRate;
            
            threshold = parameters.threshold;
            
            peakAmplitude = parameters.peakAmplitude;
            
            % -------------------------------------------------------------
            
            phoneTrainingDir = [rootDir phoneTrainingDir];
            assertDirectory(phoneTrainingDir);
                        
            phoneTestingDir = [rootDir phoneTestingDir];
            assertDirectory(phoneTestingDir);
            
            sacRootDir = [rootDir sacRootDir];
            assertDirectory(sacRootDir);
            
            % -------------------------------------------------------------
            loadCachedRecords = true;
            
            if loadCachedRecords
                load('*cache/testingPhoneRecords.mat');
                load('*cache/trainingPhoneRecords.mat');
            else
                cTrainingPhoneRecords = PhoneRecord.loadPhoneRecordDir(phoneTrainingDir);
                cTestingPhoneRecords = PhoneRecord.loadPhoneRecordDir(phoneTestingDir);
            end
            
            disp(['Segmenting phone data... '  datestr(now, 'yyyy-mm-dd HH:MM:SS PM') ]);
            
            % -------------------------------------------------------------
            loadCachedSegments = true;
            saveNewSegments = false;
            
            if loadCachedSegments
                
                % test 01: 2.5s short-term, 5s long-term, 1 "dead"
                
                load('*cache/Oct18/test01/trainingSegments'); 
                load('*cache/Oct18/test01/testingNormalSegments.mat');
                
                % test 02: 2.5s short-term, 25s long-term, 1 "dead"
                
                % load('*cache/Oct18/test02/trainingSegments'); 
                % load('*cache/Oct18/test02/testingNormalSegments.mat');
                
                % Oct24: 2.5s short-term, 5s long-term, 1 "dead" 16-bit
                % Phidget data.
%                 load('*cache/Oct25/phidgetTrainingSegments_ltst.mat');
%                 cTrainingSegments = cPhidgetTrainingSegments;
%                 clear cPhidgetTrainingSegments;
%                 
%                 load('*cache/Oct25/phidgetTestingSegments_ltst.mat');
%                 cTestingNormalSegments = cPhidgetTestingSegments;
%                 clear cPhidgetTestingSegments;
            else
                
                cTrainingSegments = GmLtStParameterSelection.segmentPhoneRecords(cTrainingPhoneRecords, segmentLength, sampleRate);
                cTestingNormalSegments = GmLtStParameterSelection.segmentPhoneRecords(cTestingPhoneRecords, segmentLength, sampleRate);
                disp(['Done segmenting phone data. ' datestr(now, 'yyyy-mm-dd HH:MM:SS PM')])
                
                if saveNewSegments
                    disp('Saving segments...')
                    save('*cache/trainingSegments.mat', 'cTrainingSegments');
                    save('*cache/testingNormalSegments.mat', 'cTestingNormalSegments');
                    save('*cache/parameters.mat', 'segmentLength', 'sampleRate', 'phoneTrainingDir', 'phoneTestingDir');
                    disp('Done saving.')
                end
                
            end
            
            % -------------------------------------------------------------
            % Subsample the phone segments. 
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
            
            cTrainingSegments = cTrainingSegments(trainingIndicesSubset);
            cTestingNormalSegments = cTestingNormalSegments(testingIndicesSubset);
            
            % LOOK: I'm switching them:
            temp = cTrainingSegments;
            cTrainingSegments = cTestingNormalSegments;
            cTestingNormalSegments = temp;
            clear temp;
            % -------------------------------------------------------------
            
            
            % clear variables that are no longer used:
            clear cTrainingPhoneRecords
            clear cTestingPhoneRecords
            
            cSacRecords = SacLoader.loadSacRecords(sacRootDir);
            
            %
            % Create the correct onset segments
            %
            %
            cSyntheticSegments= ...
                SegmentSynthesizer.createOnsetSegments(cTestingNormalSegments, cSacRecords, ...
                ltLength+deadTime, stLength, threshold, peakAmplitude, sampleRate);
            
            disp('Done Segmenting')
            
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
            
            % Loop over all parameter combinations
            
            AUC = zeros(nParameters,1);
            cTP = cell(nParameters,1);
            cFP = cell(nParameters,1);
            models = cell(nParameters,1);
            cThresholds = cell(nParameters,1);
            
            disp('Starting Main Loop')
            disp(datestr(now, 'yyyy-mm-dd HH:MM:SS PM'));
            parfor i=1:nParameters
                disp(i)
                % unpack parameters
                params = cParams{i};
                nFFT = params.numFrequencyCoefficients;
                nMoms = params.numMoments;
                nGaussians = params.numGaussians;
                dimensionsRetained = params.dimensionsRetained;
                
                [cTrainingFeatures, C, mu, sigma ]= ...
                    GmLtStParameterSelection.computeTrainingLtStFeatures(cTrainingSegments, ltLength, stLength, nFFT, nMoms, dimensionsRetained, 2); % 2 is the "normal label"
                
                
                params.C = C;
                params.mu = mu;
                params.sigma = sigma;
                
                cTestingFeatures = ...
                    GmLtStParameterSelection.computeTestingLtStFeatures(cTestingNormalSegments, cSyntheticSegments, ltLength, stLength, nFFT, nMoms, C, mu, sigma, dimensionsRetained);
                
                % learn GMM
                gm = GaussianMixture.learnGaussianMixture(cTrainingFeatures, nGaussians, 1); % <=== Magic Number
                
                params.gm = gm;
                
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
                cThresholds{i} = Thresholds;
                cParams{i} = params; % save C, mu, sigma
            end
            disp('Main loop done.');
            disp(datestr(now, 'yyyy-mm-dd HH:MM:SS PM'));
            
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
        
        function cSegments = ...
                segmentPhoneRecords(cPhoneRecords, segmentLength, sampleRate)
            %
            %
            import synthetic.*
            import phone.*
            import timeSeries.*
            
            cSegments = {};
            
            for i=1:length(cPhoneRecords)
                phoneRecord = cPhoneRecords{i};
                cNewSegments = SegmentSynthesizer.segmentPhoneRecord(phoneRecord, segmentLength, sampleRate);
                cSegments = [cSegments; cNewSegments];
            end
        end
        
        % ----------------------------------------------------------------
        
        function [cFeatures, C, mu, sigma] = ...
                computeTrainingFeatures(cTrainingSegments, nFreqZ, nMomZ, nFreqXY, nMomXY, dimensionsRetained, label)
            % compute a base feature, and then perform PCA
            %
            % compute base features
            % compute PCA parameters
            % apply PCA parameters to compute PcaFeatures
            % return features and PCA parameters
            %
            import gmm.*
            import feature.*
            
            cBaseFeatures = GmLtStParameterSelection.computeBaseFeature(cTrainingSegments, nFreqZ, nMomZ, nFreqXY, nMomXY, label);
            
            [C, mu, sigma] = PcaFeature.computePcaParameters(cBaseFeatures);
            
            cFeatures = GmLtStParameterSelection.computePcaFeatures(cBaseFeatures, C, mu, sigma, dimensionsRetained);
            
        end
        
        % ----------------------------------------------------------------
        
        
        
        function [cFeatures, C, mu, sigma] = ...
                computeTrainingLtStFeatures(cSegments, ltLength, stLength, nFreq, nMom, dimensionsRetained, label)
            % compute a base LtStFeature, and then perform PCA
            %
            % Input:
            %   cSegments - cell array of UniformTimeSeries
            %      objects.
            %   ltLength - length in seconds of long-term buffer
            %   stLength - length in seconds of short-term buffer
            %   nFreq - number of frequency coefficients for both
            %       short-term and long-term buffers
            %   nMom - number of moments for both short-term and long-term
            %       buffers
            %   dimensionsRetained - number of dimensions to retain when
            %      performing PCA
            %   label - label of features
            %
            % Output:
            %   cFeatures - cell array of feature objects
            %   C - PCA matrix
            %   mu - mean of training data
            %   sigma - standard deviation of training data
            %
            import gmm.*
            import feature.*
            
            cBaseFeatures = ...
                GmLtStParameterSelection.computeLtStFeature(cSegments, ltLength, nFreq, nMom, stLength, nFreq, nMom, label);
            
            [C, mu, sigma] = PcaFeature.computePcaParameters(cBaseFeatures);
            
            cFeatures = GmLtStParameterSelection.computePcaFeatures(cBaseFeatures, C, mu, sigma, dimensionsRetained);
            
        end
        
        % ----------------------------------------------------------------
        
        function cFeatures = ...
                computeTestingFeatures(cNormalSegments, cAnomalySegments, nFreqZ, nMomZ, nFreqXY, nMomXY, C, mu, sigma, dimensionsRetained)
            % compute base normal features
            % compute base anomaly features
            % concatenate cell arrays
            % compute PCA features
            %
            import gmm.*
            import feature.*
            
            cNormalBaseFeatures = GmLtStParameterSelection.computeBaseFeature(cNormalSegments,nFreqZ, nMomZ, nFreqXY, nMomXY, 2); % 2 is label of normal data
            cAnomalyBaseFeatures = GmLtStParameterSelection.computeBaseFeature(cAnomalySegments,nFreqZ, nMomZ, nFreqXY, nMomXY, 1); % 1 is label for anomaly data
            
            cBaseFeatures = [cNormalBaseFeatures; cAnomalyBaseFeatures];
            
            % check the labels
            labels = Feature.unpackLabels(cBaseFeatures);
            
            nNormal = length(cNormalBaseFeatures);
            nAnomaly = length(cAnomalyBaseFeatures);
            
            expectedLabels = [2*ones(nNormal,1); 1*ones(nAnomaly,1)];
            
            if any((size(labels) == size(expectedLabels)) == 0)
                disp(size(labels))
                disp(size(expectedLabels))
                error('labels and expectedLabels disagree in size');
            end
            
            if any(labels ~= expectedLabels)
                error('computeTestingFeatures: wrong labels')
            end
            
            cFeatures = GmLtStParameterSelection.computePcaFeatures(cBaseFeatures, C, mu, sigma, dimensionsRetained);
            
        end
        
        % ----------------------------------------------------------------
        
        function cFeatures = ...
                computeTestingLtStFeatures(cNormalSegments, cAnomalySegments, ltLength, stLength, nFreq, nMom, C, mu, sigma, dimensionsRetained)
            %
            % Input:
            %   cNormalSegments - cell array of UniformTimeSeries
            %      objects.
            %   cAnomalySegments - cell array of UniformTimeSeries
            %      objects.
            %   ltLength - length in seconds of long-term buffer
            %   stLength - length in seconds of short-term buffer
            %   nFreq - number of frequency coefficients for both
            %       short-term and long-term buffers
            %   nMom - number of moments for both short-term and long-term
            %       buffers
            %   C - PCA matrix
            %   mu - mean of training data
            %   sigma - standard deviation of training data
            %   dimensionsRetained - number of dimensions to retain when
            %      performing PCA
            %
            import gmm.*
            import feature.*
            
            cNormalBaseFeatures = ...
                GmLtStParameterSelection.computeLtStFeature(cNormalSegments, ltLength, nFreq, nMom, stLength, nFreq, nMom, 2); % 2 is label of normal data
            cAnomalyBaseFeatures = ...
                GmLtStParameterSelection.computeLtStFeature(cAnomalySegments, ltLength, nFreq, nMom, stLength, nFreq, nMom, 1); % 2 is label of anomaly data
            
            cBaseFeatures = [cNormalBaseFeatures; cAnomalyBaseFeatures];
            
            % check the labels
            labels = Feature.unpackLabels(cBaseFeatures);
            
            nNormal = length(cNormalBaseFeatures);
            nAnomaly = length(cAnomalyBaseFeatures);
            
            % This label check was for debugging once. Probably not needed.
            expectedLabels = [2*ones(nNormal,1); 1*ones(nAnomaly,1)];
            if any(labels ~= expectedLabels)
                error('computeTestingFeatures: wrong labels')
            end
            
            cFeatures = GmLtStParameterSelection.computePcaFeatures(cBaseFeatures, C, mu, sigma, dimensionsRetained);
            
        end
        
        % ----------------------------------------------------------------
        
        function cFeatures = ...
                computeBaseFeature(cSegments, nFreqZ, nMomZ, nFreqXY, nMomXY, label)
            % compute base features
            % compute PCA parameters
            % apply PCA parameters to compute PcaFeatures
            % return features and PCA parameters
            %
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
            
            %             L = Feature.unpackLabels(cFeatures);
            %             if  any(L ~= label*ones(nSegments,1))
            %                 error('wrong labels!')
            %             end
        end
        
        % ----------------------------------------------------------------
        
        function cFeatures = computeLtStFeature(cSegments, ltLength, nFLong, nMLong, stLength, nFShort, nMShort, label)
            %
            import gmm.*
            import feature.*
            import cell.*
            
            nSegments = length(cSegments);
            cFeatures = cell(nSegments,1);
            
            for segIndex = 1:nSegments
                segment = cSegments{segIndex};
                try
                    ltStFeature = LtStFeature(segment, ltLength, nFLong, nMLong, stLength, nFShort, nMShort, label);
                    cFeatures{segIndex} = ltStFeature;
                catch err
                    disp(err.message)
                end
                
            end
            
            % remove empty cells (caused by exceptions)
            cFeatures = deleteEmptyCells(cFeatures);
        end
        % ----------------------------------------------------------------
        
        function cFeatures = ...
                computePcaFeatures(cBaseFeatures, C, mu, sigma, dimensionsRetained)
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

