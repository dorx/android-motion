classdef GaussianMixture
    % GaussianMixture - mixture of Gaussian distributions
    %   provides a wrapper for the implementation in emGaussian   
    %
    % author: Matt Faulkner
    % 
    
    % ====================================================================
    
    properties
        nGaussians      % number of Gaussians, also called "k"
        dataDimensions  % dimensionality of data point

        mu              % (d x k) Each column is a dx1 vector of means
        Sigma           % (d x d x k) Each page (i.e. S(:,:,i)) is a dxd covariance matrix
        weight          % (k x 1) Mixing weights
    end
    
    % ====================================================================
    
    methods(Static)
              
        % ----------------------------------------------------------------
        
        function obj = learnGaussianMixture(X, k, nRepetitions)
           % Estimate a Gaussian Mixture Model from data
           %
           % Input:
           %    X - (d x n) matrix of data. Each column is a data point.
           %        Alternatively, a cell array of Feature objects.
           %    k - number of Gaussians used in the mix
           %    nRepetitions - (optional) number of times to run EM. The
           %        model assigning highest log likelihood to the training
           %        data is kept. Default 1.
           %
           import gmm.*
           import gmm.emGaussian.*
           import check.*
           import feature.*
           
           assert(isPositiveScalar(k));
           
           if nargin == 2
               nRepetitions = 1;
           end
           
           assert(isPositiveScalar(nRepetitions))
           
           if iscell(X)
               % convert from cell array of Feature objects to matrix of
               % feature vectors
               if any(cellfun(@isempty,X))
                    error('X contains empty cells')
                end
               X = Feature.unpackFeatureVectors(X);
           end
           
           [d,n] = size(X);
           
           % Makes each column a cell entry.
           data = mat2cell(X,d,ones(n,1));
           
           sumP = zeros(nRepetitions,1);
           models = cell(nRepetitions,1);
           
           % Is this the best way, or should I do several runs, and
           % evaluate each on a held-out subset of the training data?
           % I think this is okay, since I'm trying to find the mamimum
           % likelihood parameters.
           for r = 1:nRepetitions
               
               % dists is of form { { weight, mean, sigma }, {weight, mean, sigma}, ... }
               dists = emGaussian(data, k);
               
               model.weight = zeros(k,1);
               model.mu = zeros(d,k);
               model.Sigma = zeros(d,d,k);
               
               for i=1:k
                   model.weight(i) = dists{i}{1};
                   model.mu(:,i) = dists{i}{2};
                   model.Sigma(:,:,i) = dists{i}{3};
               end
               
               gm = GaussianMixture(model.mu, model.Sigma, model.weight);
               P = gm.evaluateProbability(X);
               sumP(r) = sum(log(P));
               models{r} = gm;
           end
           
           [maxVal, index] = max(sumP);
           disp(['maximum sum LLH: ' num2str(maxVal)])
           obj = models{index};
           
        end 
        

        % ----------------------------------------------------------------
        
        
    end
    
    % ====================================================================
    
    methods
        
        % ----------------------------------------------------------------
        
        function obj = GaussianMixture(mu, Sigma, weight)
            % constructor
            %
            % mu - (d x k) Each column is a dx1 vector of means
            % Sigma - (d x d x k) Each page (i.e. S(:,:,i)) is a dxd covariance matrix
            % weight - (k x 1) Mixing weights
            %
            import gmm.*
            import check.*
            [d,k] = size(mu);
            
            if any(size(Sigma) ~= size(zeros(d,d,k)))
               error('Sigma has inconsisten dimensions') 
            end
            
            if any(size(weight) ~= size(zeros(k,1)) )
                error('weight has inconsistent dimensions')
            end
            
            obj.nGaussians = k;
            obj.dataDimensions = d;
            obj.mu = mu;
            obj.weight = weight;
            obj.Sigma = Sigma;
        end
        
        % ----------------------------------------------------------------
        
        function P = evaluateProbability(obj, X)
           % Evaluate the probability of data under the Gaussian mixture model
           %
           % Input:
           %    X - (d x n) matrix. Each column is a data point.
           %        Alternatively, a cell array of Feature objects.
           %
           % Output:
           %    P - (n x 1) vector of probabilities
           %
           import gmm.*
           import check.*
           import feature.*
           
           if iscell(X)
               % convert from cell array of Feature objects to matrix of
               % feature vectors
               if any(cellfun(@isempty,X))
                    error('X contains empty cells')
                end
               X = Feature.unpackFeatureVectors(X);
           end
           
           assert( size(X,1) == obj.dataDimensions )
           
           nDataPoints = size(X,2);
           
           P = zeros(nDataPoints,1);
           
           
           for i = 1:nDataPoints
               p = 0;
               x = X(:,i);
               for j = 1:obj.nGaussians
                   muJ = obj.mu(:,j);
                   sigmaJ = obj.Sigma(:,:,j);
                   % mvnpdf wants x and mu as row vectorsdists = emGaussian(data, k);
                   pJ = mvnpdf(x', muJ', sigmaJ);
                   weightJ = obj.weight(j);
                   p = p + weightJ * pJ;
               end
               P(i) = p;
           end
        end
        
        % ----------------------------------------------------------------
        
        
    end
    
    % ====================================================================
    
end

