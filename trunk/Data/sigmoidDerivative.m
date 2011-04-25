function [S] = sigmoidDerivative(wt_x)
% sigmoidDerivative is the logistic function 1/(1+e^-t)'s derivative
%   This is -e^-t * (1+e^-t)^2
    num = exp(-wt_x);
    den = ones(length(wt_x(:, 1)), length(wt_x(1, :))) + num;
    den = den.^2;
    S = num ./ den;
end

