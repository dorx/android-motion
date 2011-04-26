clear all; % cleans up all variables
close all; % closes all figures
clc; % clean up the command window too

A = load('C:\Users\AlexFandrianto\Documents\MATLAB\CS141\BackProp\Data\Alex_running_04051515.acsn');
B = load('C:\Users\AlexFandrianto\Documents\MATLAB\CS141\BackProp\Data\Alex_biking_04121521.acsn');

C = load('C:\Users\AlexFandrianto\Documents\MATLAB\CS141\BackProp\Data\Doris_running_04101750.acsn');
D = load('C:\Users\AlexFandrianto\Documents\MATLAB\CS141\BackProp\Data\Daiwei_biking_04121519.acsn');

data = zeros(40, 3);
values = zeros(40, 1);

data(1:20, :) = reduction1(A, 20, 3, 650, 100);
data(21:40, :) = reduction1(B, 20, 3, 650, 100);
values(1:20, :) = 1;

dataTest = zeros(100, 3);
valuesTest = zeros(100, 1);

dataTest(1:50, :) = reduction1(C, 50, 33, 650, 100);
dataTest(51:100, :) = reduction1(D, 50, 33, 650, 100);
valuesTest(1:50, :) = 1;



% Layer 0 has 2 (+1 threshold) input
    % This would be our random point in the grid.
% Layer 1 has 10 inputs (+1 threshold) input
% Layer 2 has 10 inputs (+1 threshold) input
% Layer 3 has 1 output
    % Our guess should be compared to the actual value.

NUM_IN_LAYER1 = 5;
NUM_IN_LAYER2 = 5;
    
weights1 = randn(NUM_IN_LAYER1, length(data(1, :)) + 1); % This is a 2+1 by 10 matrix
weights2 = randn(NUM_IN_LAYER2, NUM_IN_LAYER1+1); % 10+1 layer 1 inputs turn into 10 layer2 inputs
weights3 = randn(1, NUM_IN_LAYER2+1); % 10+1 layer 2 inputs turn into the final output

% I'll be using this sigmoid: (logistic) 1/(1+e^-t)

%scaledPoints = points / length(mickey(:, 1)); % scale the inputs down by the size of Mickey.
lambda = .1;

oldMean = 1;
errors1 = zeros(length(data), 1);
iteration = 0;
meanTrialError = []
meanTestError = []
while iteration < 500%abs(oldMean - mean(errors1)) > 10^-7
    %oldMean = mean(errors1);
    iteration = iteration + 1;
    display(iteration);%display(oldMean);
    mean(errors1)
    meanTrialError = [meanTrialError, mean(errors1)];
    
    for i=1:length(data) %i=randperm(900)% go in a random order through the points
        pt = data(i, :)';
        input0 = [pt; 1];
        w1_x0 = weights1 * input0;
        input1 = [sigmoid(w1_x0); 1];
        w2_x1 = weights2 * input1;
        input2 = [sigmoid(w2_x1); 1];
        w3_x2 = weights3 * input2;
        input3 = sigmoid(w3_x2); % this is also the output

        expected = values(i);%mickey(points(i, 1), points(i, 2));
        error = errorFunction(expected, input3);
        errors1(i, 1) = error;
        %disp(points(i, 1));
        %disp(points(i, 2));
        %disp(expected);
        if i == 40
            %disp(input0');
            %disp(input1');
            %disp(input2');
            %disp(input3');
        end
        %disp(error);

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
        %d2 = d2(1:length(d2) - 1);
        dE2 = d2 * input1';
        
        temp = 0;
        for i=1:length(d2)
            temp = weights2(:, i) * d2(i);
        end
        temp = weights2' * d2;
        d1 = sigmoidDerivative(w1_x0) .* temp(1:length(temp)-1); %-1 because of the threshold input at that layer
        %d1 = d1(1:length(d1)-1);
        dE1 = d1 * input0';


        old3 = weights3;
        old2 = weights2;
        old1 = weights1;

        weights3 = weights3 - lambda * dE3;
        weights2 = weights2 - lambda * dE2;
        weights1 = weights1 - lambda * dE1;
        
        %keyboard

    end
    
%     errors3 = zeros(37, 37);
%     minipic = zeros(37, 37);
%     for i=1:37
%         for j=1:37
%             input0 = [i*10/375; j*10/375; 1];
%             w1_x0 = weights1 * input0;
%             input1 = [sigmoid(w1_x0); 1];
%             w2_x1 = weights2 * input1;
%             input2 = [sigmoid(w2_x1); 1];
%             w3_x2 = weights3 * input2;
%             input3 = sigmoid(w3_x2);
%             
%             minipic(i, j) = input3;
%             if (input3 > .8)
%                 minipic(i, j) = 1;
%             elseif (input3 < .2)
%                 minipic(i, j) = 0;
%             end
% 
%             expected = mickey(i*10, j*10);
%             errors3(i, j) = errorFunction(expected, input3);
%         end
%     end
    errors3 = zeros(length(dataTest), 1);
    for i=1:length(dataTest)
        pt = dataTest(i, :)';
        input0 = [pt; 1];
        w1_x0 = weights1 * input0;
        input1 = [sigmoid(w1_x0); 1];
        w2_x1 = weights2 * input1;
        input2 = [sigmoid(w2_x1); 1];
        w3_x2 = weights3 * input2;
        input3 = sigmoid(w3_x2);
        
        expected = valuesTest(i);
        errors3(i) = errorFunction(expected, input3);
    end
    meanTestError = [meanTestError, mean(errors3)];
    %imagesc(minipic);
    %pause(.005);
end

plot(1:length(meanTestError), meanTestError, 'r', 1:length(meanTrialError), meanTrialError, 'g')
% errors1 = zeros(900, 1);
% for i=1:length(scaledPoints)
%     pt = scaledPoints(i, :)';
%     input0 = [pt; 1];
%     w1_x0 = weights1 * input0;
%     input1 = [sigmoid(w1_x0); 1];
%     w2_x1 = weights2 * input1;
%     input2 = [sigmoid(w2_x1); 1];
%     w3_x2 = weights3 * input2;
%     input3 = sigmoid(w3_x2);
% 
%     expected = mickey(points(i, 1), points(i, 2));
%     errors1(i) = errorFunction(expected, input3);
% end

% errors2 = zeros(375, 375);
% mickey2 = zeros(375, 375);
% for i=1:375
%     for j=1:375
%         input0 = [i/375; j/375; 1];
%         w1_x0 = weights1 * input0;
%         input1 = [sigmoid(w1_x0); 1];
%         w2_x1 = weights2 * input1;
%         input2 = [sigmoid(w2_x1); 1];
%         w3_x2 = weights3 * input2;
%         input3 = sigmoid(w3_x2);
%         
%         mickey2(i, j) = input3;
%         
%         expected = mickey(i, j);
%         errors2(i, j) = errorFunction(expected, input3);
%     end
% end
% 
% mean(mean(errors2))
% imagesc(mickey2)
% mickey3 = mickey2;
% for i=1:375
%     for j=1:375
%         if mickey2(i, j) > .8
%             mickey3(i, j) = 1;
%         elseif mickey2(i ,j) < .2
%             mickey3(i, j) = 0;
%         end
%     end
% end

%% Images for this section
% imagesc(mickey3)
% imagesc(mickey3 - mickey)
% plot(1:1000, meanTrialError, 1:1000, meanTestError)
% ylabel('Average Error: (output - expected)^2');
% xlabel('Number of Epochs: 900 random samples each');
% title('Error for 2 hidden layers with 10 units each')
% legend('Average Training Error', 'Average Test Error')