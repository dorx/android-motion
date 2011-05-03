function [w1, w2, w3, meanTrialError, meanTestError, ISError, OOSError, weights1, weights2, weights3] = ...
    backProp3Layer(data, values, dataTest, valuesTest, NUM_IN_LAYER1, NUM_IN_LAYER2, maxIterations, lambda)
%backProp3Layer Back propagation on a 3 layer network.
%   Layer 0 = inputs = # nodes
%   Layer 1 = has NUM_IN_LAYER1 nodes
%   Layer 2 = has NUM_IN_LAYER2 nodes
%   Layer 3 = has 1 output from 0 to 1. 1 <=> Y, 0 <=> N

%   Other Inputs:
%   data is the trainingData that should be classified
%   values is the corresponding values for the trainingData
%   dataTest is the testData that should be classified
%   valuesTest is the corresponding values for the testData


%   OPTIONAL INPUTS:
%   NUM_IN_LAYER1 (=5), NUM_IN_LAYER2 (=5) as described above
%   maxIterations (=500) is the number of times you want to train the data before
%       stopping. One would adjust this to whatever value works well in
%       practice for the data being learned.
%   lambda (=.1) is your learning rate, .1 is usually good.

%   If you don't input these, they get default values listed above.


%   Outputs:
%   w1 to w3 are the weight matrices. Use the classify function.
%       The w1, w2, and w3 returned are the ones which produced lowest
%       out-of-sample error. (so lowest mTestError)
%   ISError = corresponding in-sample error
%   OOSError = corresponding out-of-sample error

%   meanTrialError = the mean Trial Error vector with respect to Iteration #
%   meanTestError = the mean Test Error vector with respect to Iteration #


%   Notes:
%   errorFunction uses meanSquaredError so errors near .25 indicate
%       chance level learning
%   classify is a function that applies the sigmoid function after every
%       weight matrix is multiplied.


%   Handling optional inputs that were not given
switch nargin
    case 4
        NUM_IN_LAYER1 = 5;
        NUM_IN_LAYER2 = 5;
        maxIterations = 1000;
        lambda = .1;
    case 5
        NUM_IN_LAYER2 = 5;
        maxIterations = 1000;
        lambda = .1;
    case 6
        maxIterations = 1000;
        lambda = .1;
    case 7
        lambda = .1;
end

weights1 = randn(NUM_IN_LAYER1, length(data(1, :)) + 1); % This is a 2+1 by 10 matrix
weights2 = randn(NUM_IN_LAYER2, NUM_IN_LAYER1+1); % 10+1 layer 1 inputs turn into 10 layer2 inputs
weights3 = randn(1, NUM_IN_LAYER2+1); % 10+1 layer 2 inputs turn into the final output

% I'll be using this sigmoid: (logistic) 1/(1+e^-t)



ISError = 1;
OOSError = 1;
w1 = weights1;
w2 = weights2;
w3 = weights3;

oldMean = .25;
errors1 = ones(length(data), 1) * oldMean;
iteration = 0;
meanTrialError = ones(maxIterations, 1);
meanTestError = ones(maxIterations, 1);
while iteration < maxIterations
    
    iteration = iteration + 1;
    %display(iteration);
    %display(mean(errors1));
    
    meanTrialError(iteration) = mean(errors1);
    
    for i=1:length(data)%randperm(length(data)) % go in a random order through the points
        pt = data(i, :)';
        input0 = [pt; 1];
        w1_x0 = weights1 * input0;
        input1 = [sigmoid(w1_x0); 1];
        w2_x1 = weights2 * input1;
        input2 = [sigmoid(w2_x1); 1];
        w3_x2 = weights3 * input2;
        input3 = sigmoid(w3_x2); % this is also the output

        expected = values(i);
        error = errorFunction(expected, input3);
        errors1(i, 1) = error;

        % THETA'(S) = 1 - THETA(S)^2 where THETA(S) = X
        % delta_L = 2(x_L - y) * (1 - x_L^2)
        % d_l = (1 - x_l^2) * (d_l+1' * weights3)
        
        d3 = (2*(input3 - expected)) .* sigmoidDerivative(w3_x2);
        dE3 = d3 * input2';
        temp = 0;
        for i=1:length(d3)
            temp = weights3(:, i) * d3(i);
        end
        d2 = sigmoidDerivative(w2_x1) .* temp;

        dE2 = d2 * input1';
        
        temp = weights2' * d2;
        d1 = sigmoidDerivative(w1_x0) .* temp(1:length(temp)-1); %-1 because of the threshold input at that layer

        dE1 = d1 * input0';


        weights3 = weights3 - lambda * dE3;
        weights2 = weights2 - lambda * dE2;
        weights1 = weights1 - lambda * dE1;
        

    end
    
%    errors3 = zeros(length(dataTest), 1);
%     for i=1:length(dataTest)
%         pt = dataTest(i, :)';
%         input0 = [pt; 1];
%         w1_x0 = weights1 * input0;
%         input1 = [sigmoid(w1_x0); 1];
%         w2_x1 = weights2 * input1;
%         input2 = [sigmoid(w2_x1); 1];
%         w3_x2 = weights3 * input2;
%         input3 = sigmoid(w3_x2);
%         
%         expected = valuesTest(i);
%         errors3(i) = errorFunction(expected, input3);
%     end
    got = classify3Layer(dataTest', weights1, weights2, weights3)';
    errors3 = errorFunction(valuesTest, got);
    meanTestError(iteration) = mean(errors3);
    
    
    if (meanTestError(iteration) < OOSError)
        OOSError = meanTestError(iteration);
        ISError = meanTrialError(iteration);
        w1 = weights1;
        w2 = weights2;
        w3 = weights3;
    end
end



end

