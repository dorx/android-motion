function A = randomSubset( n, k )
% random subset of k elements
%   Randomly select k of the n elements, without replacement
%
% Input:
%   n - total number of elements
%   k - number of elements to select
%
% Output:
%   A - row vector of indices, in [1,n]
%

if k >= n
    A = 1:n;
    return
else
    A = randperm(n);
    A = sort(A(1:k));
end

end

