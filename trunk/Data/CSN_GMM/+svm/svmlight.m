function Y=svmlight(xtrain, ytrain, xtest, params)
% Wrapper for svmlight, version 6.02
% write matrices in sparse format to data file that can be used by svmlight.
% Columns are variables, rows are observations. 
%
% Input:
%   xtrain - (mxn) matrix. Each row is a data point
%   ytrain - (mx1) matrix. Training labels. Might need to be +/- 1 ?
%   xtest - (mtest x n) matrix. Each row is a data point
%   params - string of parameters for SVM Light's svm_learn. Must end with
%           a space.
%
% Output:
%   Y - (mTest x 1) vector of predictions for xtest
%
% These steps are made: 
% 1. output matlab matrix to text file
% 2. format text file for svm (awk)
% 3. create classification model (svm_learn)
% 4. apply classification model (svm_classify)
%
% All files are written in the /tmp/ directory, if you are on windows you might 
% want to change that to the current directory ("."). Obviously you need awk 
% installed for this function to work. Assumes svm-light is installed in the svmlight 
% subdirectory (change path if necessary). 
%
% Example: 
% Y=svmlight(Xtrain, Ytrain, Xtest, '-t 0 -c 0.5 ');
% (if you set parameters for svmlight don't forget to include the learning options!)
%
% (c) Benjamin Auffarth, 2008
% modified by Debajyoti Ray, 2010
% Further modified by Matt Faulkner, 2010

import java.lang.String

if nargin<4
  params='-t 0 -c 0.5 ';
end

% TODO: format params in case it doesn't have a trailing white space. A
% good idea is to use java's String.trim to remove all white space, then
% explicitly add in the correct spaces when making the system commands.

% explicitly specify trailing whitespace
params = String(params);
params = params.trim();
params = char(params); % convert back to a char array, so Matlab can work with it

training = [ytrain, xtrain];
test = xtest;

% SVM_PATH requires a trailing slash: '/'.
% SVM_PATH = [pwd '/+svm/svmLight/']
% TODO: don't hard-code this
%SVM_PATH = '/home/mfaulk/projects/csn/android_activities/Picking/+svm/svmLight/'
SVM_PATH = '/home/mfaulkne/projects/csn/android_activities/Picking/+svm/svmLight/'

trainfile=sparse_write(training);
[s,w]=system([SVM_PATH 'svm_learn ' params ' ' trainfile '.svm2 ' trainfile '.model']);
if s 
  disp('error in executing smv-light!');w,
  disp('Check that the SVM_PATH variable is correct for your machine, and that the svm light code has been compiled.')
  error('svm_learn not found or returned error');
end

testfile=sparse_write(test);
[s,w]=system([SVM_PATH 'svm_classify -v 0  ' testfile '.svm2 ' trainfile '.model ' testfile '.dat']);
if s 
  disp('error in executing smv-light!');w,
  error('svm_classify not found or returned error');
end
Y=dlmread([testfile '.dat']);
end

function fname=sparse_write(M)
  [a,fname]=system('date +/tmp/_svm_%F_-%H:%M_%S%N');
  fname=fname(1:end-1); % get rid of newline character
  dlmwrite([fname '.svm1'],M,'delimiter',' '); 
  system(['awk -F" " ''{printf $1" "; for (i=2;i<=NF;i++) {printf i-1":"$i " "}; print ""}'' ' fname '.svm1 > ' fname '.svm2']);
end

% ========================================================================
%
% svm_learn is called with the following parameters:
% 
% svm_learn [options] example_file model_file
% 
% Available options are:
% 
% General options:
%          -?          - this help
%          -v [0..3]   - verbosity level (default 1)
% Learning options:
%          -z {c,r,p}  - select between classification (c), regression (r), and 
%                        preference ranking (p) (see [Joachims, 2002c])
%                        (default classification)          
%          -c float    - C: trade-off between training error
%                        and margin (default [avg. x*x]^-1)
%          -w [0..]    - epsilon width of tube for regression
%                        (default 0.1)
%          -j float    - Cost: cost-factor, by which training errors on
%                        positive examples outweight errors on negative
%                        examples (default 1) (see [Morik et al., 1999])
%          -b [0,1]    - use biased hyperplane (i.e. x*w+b0) instead
%                        of unbiased hyperplane (i.e. x*w0) (default 1)
%          -i [0,1]    - remove inconsistent training examples
%                        and retrain (default 0)
% Performance estimation options:
%          -x [0,1]    - compute leave-one-out estimates (default 0)
%                        (see [5])
%          -o ]0..2]   - value of rho for XiAlpha-estimator and for pruning
%                        leave-one-out computation (default 1.0) 
%                        (see [Joachims, 2002a])
%          -k [0..100] - search depth for extended XiAlpha-estimator
%                        (default 0)
% Transduction options (see [Joachims, 1999c], [Joachims, 2002a]):
%          -p [0..1]   - fraction of unlabeled examples to be classified
%                        into the positive class (default is the ratio of
%                        positive and negative examples in the training data)
% Kernel options:
%          -t int      - type of kernel function:
%                         0: linear (default)
%                         1: polynomial (s a*b+c)^d
%                         2: radial basis function exp(-gamma ||a-b||^2)
%                         3: sigmoid tanh(s a*b + c)
%                         4: user defined kernel from kernel.h
%          -d int      - parameter d in polynomial kernel
%          -g float    - parameter gamma in rbf kernel
%          -s float    - parameter s in sigmoid/poly kernel
%          -r float    - parameter c in sigmoid/poly kernel
%          -u string   - parameter of user defined kernel
% Optimization options (see [Joachims, 1999a], [Joachims, 2002a]):
%          -q [2..]    - maximum size of QP-subproblems (default 10)
%          -n [2..q]   - number of new variables entering the working set
%                        in each iteration (default n = q). Set n<q to prevent
%                        zig-zagging.
%          -m [5..]    - size of cache for kernel evaluations in MB (default 40)
%                        The larger the faster...
%          -e float    - eps: Allow that error for termination criterion
%                        [y [w*x+b] - 1] = eps (default 0.001) 
%          -h [5..]    - number of iterations a variable needs to be
%                        optimal before considered for shrinking (default 100) 
%          -f [0,1]    - do final optimality check for variables removed by
%                        shrinking. Although this test is usually positive, there
%                        is no guarantee that the optimum was found if the test is
%                        omitted. (default 1) 
%          -y string   -> if option is given, reads alphas from file with given
%                         and uses them as starting point. (default 'disabled')
%          -# int      -> terminate optimization, if no progress after this
%                         number of iterations. (default 100000)
% Output options: 
%          -l char     - file to write predicted labels of unlabeled examples 
%                        into after transductive learning 
%          -a char     - write all alphas to this file after learning (in the 
%                        same order as in the training set)
