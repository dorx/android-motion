function [ classified ] = classify3LayerStrict(points, w1, w2, w3 )
%classify3LayerStrict classifies the inputted points. Only +1 or 0 labels
%   points: a x N
%   w1: b x (a+1)
%   w2: c x (b+1)
%   w3: 1 x c
%   classified: 1 x N matrix

    input0 = [points; ones(1, length(points(1, :)))];
    w1_x0 = w1 * input0;
    input1 = [sigmoid(w1_x0); ones(1, length(w1_x0(1, :)))];
    w2_x1 = w2 * input1;
    input2 = [sigmoid(w2_x1); ones(1, length(w2_x1(1, :)))];
    w3_x2 = w3 * input2;
    classified = sigmoid(w3_x2);

    classified = (sign(classified * 2 - 1) + 1)/2;

end

