function [S, Ys] = subsample(Xtrain, Ytrain, num)
% returns a sample of size num containing half of each type of data
T = horzcat(Ytrain, Xtrain);
T = sort(T,1);
Ytrain = T(:, 1);
Xtrain = T(:, 2:end);
D = find(Ytrain,1,'first');
Ys = zeros(num, 1);
S = zeros(num, size(Xtrain, 2));

for i=1:(num/2)
    index = randi(D);
    Ys(i) = Ytrain(index);
    S(i,:) = Xtrain(index, :);
end
for j=(num/2+1):num
    index = randi([D size(Xtrain, 1)]);
    Ys(j) = Ytrain(index);
    S(j,:) = Xtrain(index, :);
end
end