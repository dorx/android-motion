function W = onlineSVM(Xtrain, Ytrain, lambda)
% Output:
%    W - weight vector
%
% Input:
%    Xtrain - matrix NxC of training data, where N is the number of
%    training examples and C is the length of the example vector.
%    Ytrain - (Column) vector of length N of labels {+1, -1}
%    lambda - parameter for strength of prior.
%    filename - the file to which the weight vector is saved

N = size(Xtrain, 1);        % number of training examples
D = size(Xtrain, 2);        % dimensionality of example

% Normalize input
Xtrain = Xtrain./repmat(sqrt(sum(Xtrain.^2,2)),1,D);

Iter = 5;         % number of iterations to run weight learning

% initialize weight vector
W = zeros(Iter, D);

for t=1:Iter
    % fill in the loop for updating the weight vector as you go through
    % training examples
    wi = zeros(1, D);
    for n=1:N
        % set scale of learning rate
        alpha = 1/(lambda*n);
        % if margin is violated, apply the gradient
        if Ytrain(n)*wi'*Xtrain(n,:) < 1
            wi = (1-alpha*lambda)*wi + alpha*Ytrain(n)*Xtrain(n,:);
        end
        % optionally project to ball of size sqrt(lambda)
        if norm(wi)^2 > (1/lambda)
            wi = wi/(norm(wi)*sqrt(lambda));
        end
        
    end
    W(t,:) = wi;
end

W = mean(W);
end