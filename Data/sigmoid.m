function [S] = sigmoid(wt_x)
% sigmoid is the logistic function 1/(1+e^-t)
    S = ones(length(wt_x(:, 1)), length(wt_x(1, :))) + exp(-wt_x);
    S = 1 ./ S;
end

