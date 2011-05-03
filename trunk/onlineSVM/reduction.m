function redXtrain = reduction(Xtrain)
% placeholder for now
% same reduction method as the one in reduction2
% will update once matt's code is fully understood
numFeatures = 3;
numRows = size(Xtrain, 1);
redXtrain = zeros(numRows, numFeatures);

for i=1:numRows
    redXtrain(i, :) = reduce(Xtrain(i, :));
end

redXtrain = [redXtrain(:, 1) / 10, redXtrain(:, 2), redXtrain(:, 3) / 10^5];

end

function redVec = reduce(Xvec)
Xvec = reshape(Xvec, int32(length(Xvec)/3),3);
xmag = sqrt(Xvec(:, 1).^2 + Xvec(:, 2).^2 + Xvec(:, 3).^2);
fA = abs(fft(xmag));
redVec = [mean(xmag), std(xmag), sum(fA.^2) / length(fA)];
end