function area = auc( FP, TP )
% AUC - Area Under the Curve
%   Compute the area under an ROC curve.
%
% Inputs:
%   FP - (mx1) vector of false positive values (x axis of ROC curve)
%        each element of FP must be in [0,1]
%   TP - (mx1) vector of true positive values (y axis of ROC curve)
%        each element of TP must be in [0,1]
%
% Outputs:
%   area - area under curve, a value in [0,1]
%
% NOTE: FP is sorted to be increasing
% ----------------------------------------------------------------------
checkInputs(FP,TP);

area = 0;

% Augment inputs to include points at (0,0) and (1,1). If these are
% redundant they will not change the return value.
X = [0; FP; 1];
Y = [0; TP; 1];

% enforce that X must be increasing, and re-order the corresponding Y
% points
[X I] = sort(X);
Y = Y(I);

m=size(X,1);

if any(~isfinite(X))
    error('Non-finite values in X')
end

if any(~isfinite(Y))
    error('Non-finite values in Y')
end

% compute area of trapezoids under ROC curve.
for i=2:m
    width = X(i) - X(i-1);
    if width < 0
        warning(['Negative Width: ' num2str(width)]);
        width = 0;
    end
    height = 0.5*( Y(i) + Y(i-1) );
    if height < 0
        warning('Negative Height');
        height = 0;
    end
    
    area = area + width*height;
end

if area < 0
    error(['Area is negative. Area = ' num2str(area)]);
end

if area > 1
    error(['Area is above 1. Area = ' num2str(area)]);
end

end

function checkInputs(FP, TP)
[m,n] = size(FP);
assert(n==1);
assert(size(TP,1) == m);
assert(size(TP,2) == 1);

assert(max(FP) <= 1);
assert(max(TP) <= 1);

assert(min(FP) >= 0);
assert(min(TP) >= 0);
end

