function [E] = errorFunction(expected, got)
% error function is (got - expected)^2
    E = (got - expected).^2;
end

