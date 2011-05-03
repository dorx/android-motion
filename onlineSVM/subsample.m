function [Xsub, Ysub] = subsample(X, Y, num)
% % returns a sample of size num containing half of each type of data
% T = horzcat(Ytrain, Xtrain);
% T = sort(T,1);
% Ytrain = T(:, 1);
% Xtrain = T(:, 2:end);
% D = find(Ytrain==1,1,'first');
% Ys = zeros(num, 1);
% S = zeros(num, size(Xtrain, 2));
% 
% for i=1:(num/2)
%     index = randi(D);
%     Ys(i) = Ytrain(index);
%     S(i,:) = Xtrain(index, :);
% end
% for j=(num/2+1):num
%     index = randi([D size(Xtrain, 1)]);
%     Ys(j) = Ytrain(index);
%     S(j,:) = Xtrain(index, :);
% end

N = size(X, 1);
frac = double(num)/N;
T = horzcat(Y, X);
T = sort(T,1);
Y = T(:, 1);
X = T(:, 2:end);
D = find(Y==1,1,'first');
x = vertcat(X(1:int32((D-1)*frac), :), X(D:D+int32((N-D)*frac), :));
y = vertcat(Y(1:int32((D-1)*frac), :), Y(D:D+int32((N-D)*frac), :));


orderT = randperm(size(x, 1));
Xsub = x(orderT, :);
Ysub = y(orderT, :);
% subPos = sum(Ysub==1)
% subSize = size(Xsub)
end