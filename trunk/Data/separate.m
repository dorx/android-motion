function [Xtrain, Ytrain, Xtest, Ytest] = separate(X, Y, fracTest)
N = size(X, 1);
T = horzcat(Y, X);
T = sort(T,1);
Y = T(:, 1);
X = T(:, 2:end);
D = find(Y==1,1,'first');
xtest = vertcat(X(1:int32((D-1)*fracTest), :), X(D:D+int32((N-D)*fracTest), :));
xtrain = vertcat(X(int32((D-1)*fracTest)+1:D-1, :), X(D+int32((N-D)*fracTest)+1:end, :));
ytest = vertcat(Y(1:int32((D-1)*fracTest), :), Y(D:D+int32((N-D)*fracTest), :));
ytrain = vertcat(Y(int32((D-1)*fracTest)+1:D-1, :), Y(D+int32((N-D)*fracTest)+1:end, :));

orderT = randperm(size(xtest, 1));
Xtest = xtest(orderT, :);
Ytest = ytest(orderT, :);
% testPos = sum(Ytest==1)
% testSize = size(Xtest)

order = randperm(size(xtrain, 1));
Xtrain = xtrain(order, :);
Ytrain = ytrain(order, :);
% trainPos = sum(Ytrain==1)
% trainSize = size(Xtrain)
end