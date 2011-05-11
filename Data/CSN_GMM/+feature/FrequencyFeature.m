classdef FrequencyFeature < feature.Feature
    % FrequencFeature - FFT and moments
    %   [ frequeny terms | moments | max absolute value ]
    %
    % author: Matt Faulkner
    %
    
    % ===================================================================
    
    properties
        featureVector % column vector
        nFrequencyTerms
        nMoments
        label = 0;
    end
    
    % ===================================================================
    
    methods(Static)
        function V = featurize(X , nF, nM, L)
            % compute feature(s)
            % Input:
            %   X - Each column is a vector of uniformly sampled time
            %       series data.
            %   nF - number of frequency terms to use in feature vector.
            %   nM - number of central moments (starting with the second
            %       moment) 
            %   L - column vector of integer labels
            %
            import check.*
            import feature.*
            
            [m,n] = size(X);
            
            if ~isColumnVector(L)
                error('L must be a column vector')
            end
            
            assert( n == length(L));
            
            if ~isNonNegativeScalar(nF)
                error('nF must be a non-negative scalar')
            end
            
            if ~isNonNegativeScalar(nM)
                error('nM must be a non-negative scalar')
            end
            
            % Preallocate for speed. Slight abstraction violation...
            nFrequencyTermsTemp = min( nF, floor(m/2));
            featureLength = nFrequencyTermsTemp + nM + 1;
            V = zeros(featureLength, n);
            
            for i=1:n % loop over data and create features
               labelTemp = L(i);
               feature = FrequencyFeature( X(:,i), nF, nM, labelTemp);
               V(:,i) = feature.getFeatureVector();
            end
        end
            
    end
    
    % ===================================================================
    
    methods 
        
        % ---------------------------------------------------------------
        
        function obj = FrequencyFeature(x, nF, nM, label)
            % FrequencyFeature - constructor
            % Input:
            %   x - column vector of uniformly sampled time series data
            %   nF - number of frequency terms to use in feature vector. To
            %       keep all the FFT coefficients, set nF = length(x)
            %   nM - number of central moments (starting with the second
            %       moment) 
            %   label - (optional) integer label
            %
            % Note: In order for two features to be comparable, they should
            % both have been produced from equal length time series, with
            % equal sample rates. Otherwise, the frequency terms will not
            % correspond to the same frequencies.
            %
            import check.*
            import feature.*
            
            if ~isColumnVector(x) 
                error('X must be a column vector')
            end
            
            if ~isNonNegativeScalar(nF)
                error('nF must be a non-negative scalar')
            end
            
            if ~isNonNegativeScalar(nM)
                error('nM must be a non-negative scalar')
            end
            
            if nargin == 4
                obj.label = label;
            end
            
            obj.nMoments = nM;
            
            % compute frequency terms
            
            N = length(x);
            
            % Matlab's FFT produces complex values, for both positive and
            % negtive frequencies. For real inputs, the values at negative
            % frequencies are the complex conjugate of the positive
            % frequencies. The next couple lines compute the single-sided
            % power spectra, that is, the the power in each positive
            % frequency.

            p = abs(fft(x))/(N/2); % normalized magnitude
            p = p(1:ceil(N/2)).^2; % compute power of positive frequencies
            
            % the actual frequencies depend on the duration (in seconds) of
            % x and the number of points of x. Let T be the time duration
            % of x. The frequencies are evenly spaced between 0 and the
            % Nyquist frequency (half the sampling rate)
            % freq = [0:N/2-1]/T; % maybe this should be up  (0:(N-1)/2) / T ?
            
            % take no more than nF frequency terms
            % TODO: this takes only the lowest frequency coefficients.
            % Should the frequency terms be subsampled somehow?
            %
            obj.nFrequencyTerms = min( nF, floor(N/2));
            p = p(1:obj.nFrequencyTerms);
            
            % compute central moment terms. The "1+j" skips over the first
            % moment, which is always 0
            moments = zeros(nM,1);
            for j=1:nM
                moments(j) = moment(x, 1+j); % central moments
            end
            
            % this is tossed in, too.
            maxAbs = max(abs(x));
            
            obj.featureVector = [p ; moments ; maxAbs];
            
        end
        
        % ---------------------------------------------------------------
        
        % return the length of the feature vector
        function n = length(obj)
            assertInstance(obj);
            n = length(obj.featureVector);
        end
        
        % ---------------------------------------------------------------
        
        % return the feature vector as a column vector
        function v = getFeatureVector(obj)
            assertInstance(obj);
            v = obj.featureVector;
        end
        
        % ---------------------------------------------------------------
        
        % return label of feature. Must be an integer.
        function label = getLabel(obj)
            assertInstance(obj)
            label = obj.label;
        end
        
        % ---------------------------------------------------------------
        
        function assertInstance(obj)
            assert( isa( obj, 'feature.FrequencyFeature'));
        end
    end
    
    % ===================================================================
    
end

