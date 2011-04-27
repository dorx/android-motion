function [Xtrain, Ytrain, Xtest, Ytest] = separate(X, Y, fracTest)
N = size(X, 1);
T = horzcat(Y, X);
T = sort(T,1);
Y = T(:, 1);
X = T(:, 2:end);
D = find(Y,1,'first');
xtest = vertcat(X(1:int32((D-1)*fracTest), :), X(D:int32(N-D)*fracTest, :));
xtrain = vertcat(X(int32((D-1)*fracTest)+1:end, :), X(int32(N-D)*fracTest+1:end, :));
ytest = vertcat(Y(1:int32((D-1)*fracTest), :), Y(D:int32(N-D)*fracTest, :));
ytrain = vertcat(Y(int32((D-1)*fracTest)+1:end, :), Y(int32(N-D)*fracTest+1:end, :));

orderT = randperm(size(xtest, 1));
Xtest = xtest(orderT, :);
Ytest = ytest(orderT, :);

order = randperm(size(xtrain, 1));
Xtrain = xtrain(order, :);
Ytrain = ytrain(order, :);
end