classdef PcaFeature < feature.Feature
    % PcaFeature - Applies PCA dimensionality reduction to feature vectors
    %
    % author: Matt Faulkner
    %
    
    % ===================================================================
    
    properties
        featureVector % column vector
        mu
        sigma
        label = 0;
    end
    
    % ===================================================================
    
    methods(Static)
        
        % ---------------------------------------------------------------        
        
        function [C, mu, sigma] = computePcaParameters(X)
            % computePcaParameters
            %   compute the Coefficients matrix (PCA projection matrix).
            %   This is useful for finding a good basis from training data.
            %
            % Input:
            %   X - (mxn) matrix. Each column is a data point
            %       Alternatively, a cell array of Feature objects.
            %
            %   C - princomp's (mxm) COEFF matrix
            %   mu - (mx1) vector. mean of X
            %   sigma - (mx1) vector. sample std deviation
            %
            import feature.*
            
            % if X is a cell array of Feature objects, convert to a matrix
            if iscell(X)
                if any(cellfun(@isempty,X))
                    error('X contains empty cells')
                end
                X = Feature.unpackFeatureVectors(X);
            end
            
            mu = mean(X,2);
            sigma = std(X,1,2); % the 1 is to use normalization by N, rather than N-1, to match zscore
            
            % these can be used to normalize data:
            n = size(X,2);
            X = (X - repmat(mu,1,n)) ./ repmat(sigma,1,n);
            
            % princomp requires each data point to be a row
            C = princomp(X');
            
            % Another way to normalize X and compute C. This should be the
            % same as above.
            %   C = princomp(zscore(X'));
        end
        
        % ---------------------------------------------------------------        
        
        function F =  PcaReduce(X, C, mu, sigma, k)
            % PcaReduce - reduce dimensionality of data points via PCA
            % Input:
            %   X - matrix of data. Each column is a data point.
            %   C - PCA coefficient matrix, as computed by princomp
            %   mu - mean of the data, prior to normalization, used to
            %       compute C. Column vector.
            %   sigma - std deviation of the data, prior to normalization,
            %       used to compute C. Column vector.
            %   k - number of dimensions to retain after PCA. Optional. If
            %       not specified, all dimensions are kept.
            %
            % Output:
            %   F - (k+1 x n) matrix of feature vectors. Each column is a
            %       reduced feature. (k dimensions, and projection error)
            %
            import feature.*
            import check.*
            
            [m,n] = size(X);
            [mC, nC] = size(C);
            
            assert(m == mC);
            assert(m == nC);
            
            if ~isColumnVector(mu)
                error('mu must be a column vector')
            end
            
            if ~isColumnVector(sigma)
                error('sigma must be a column vector')
            end
            
            assert( length(mu) == m )
            assert( length(sigma) == m)
            
            if nargin == 4
                k = m; 
            end
            
            if ~isNonNegativeScalar(k)
                error('k must be a non-negative scalar')
            end
            
            % normalize data 
            X = (X - repmat(mu,1,n)) ./ repmat(sigma,1,n);
            
            % princomp assumes data points are rows, so Y is in rows, too.
            Score = X'*C; % <---- check this (seems to check out...)
            
            
            if k >= m
                Y = Score;
                projectionError = zeros(1,n);
            else
                Y = Score(:, 1:k);
                %disp('k~=m')
                D = Score(:,k+1:end)'; %discarded dimensions
                projectionError = sum(D.*D,1).^0.5; % L2 norm of each column
                % BUG FIX: sum(D.*D) returns a scalar if D is a row vector.
                % Explicitly sum the columns.
            end
            
            % transpose Y to return to "column is data point" convention
            F = [Y' ; projectionError];
        end
        
        % ---------------------------------------------------------------        
        
    end
    
    % ===================================================================
    
    methods
        
        function obj = PcaFeature(X, C, mu, sigma, k, label)
            % PcaFeature - constructor
            % Input:
            %   X - column vector data point
            %   C - PCA coefficient matrix, as computed by princomp
            %   mu - mean of the data, prior to normalization, used to
            %       compute C. Column vector.
            %   sigma - std deviation of the data, prior to normalization,
            %       used to compute C. Column vector.
            %   k - number of dimensions to retain after PCA. 
            %   label - (optional) integer label
            %
            import feature.*
            import check.*

            if ~isColumnVector(X)
                error('X must be a column vector')
            end
            
            if nargin == 5
                label = 0; 
            end
            
            V = PcaFeature.PcaReduce(X, C, mu, sigma, k);
            
            obj.featureVector = V;
            obj.mu = mu;
            obj.sigma = sigma;
            obj.label = label;
        end
        
        % ---------------------------------------------------------------
        
         % retrun the length of the feature vector
        function n = length(obj)
            n = length(obj.featureVector);
        end
        
        % ---------------------------------------------------------------
        
        % return the feature vector as a column vector
        function v = getFeatureVector(obj)
            v = obj.featureVector;
        end
        
        % ---------------------------------------------------------------
        
        % return label of feature. Must be an integer.
        function label = getLabel(obj)
            label = obj.label;
        end
        
        % ---------------------------------------------------------------
        
        function assertInstance(obj)
            assert( isa( obj, 'feature.PcaFeature'));
        end
    end
        
    % ===================================================================
end

