function [ tp, fp, cellROC, sensorTP, sensorFP] = ...
    optimizeCellTruePositive( N, sensorROC, maxSensorFalsePositive, maxCellFalsePositive, faultRate)
%
% optimizeCellTruePositive
%
% 
% \begin{equation*}
%   \begin{aligned}
%     & \underset{fp, \tau}{\text{maximize}}
%     & & \Pr{R/N \geq \tau | E=1, fp,N} \\
%     & \text{subject to}
%     & & \Pr{R/N \geq \tau | E=0, fp,N} \leq maxCellFalsePositive \\
%     & %place holder
%     & & fp \leq maxSensorFalse
%   \end{aligned}
% \end{equation*}
%
% Input:
%   N - number of sensors in a cell. Positive scalar integer.
%   sensorROC - ReceiverOperatingCharacteristic object
%   maxSensorFalsePositive - maximum allowed sensor false positive rate.
%       non-negative scalar.
%   maxCellFalsePositiveRate - maximum allowed cell false positive rate. 
%       non-negative scalar
%   faultRate - optional value (in [0,1]). If supplied, it is the
%       probability that a sensor produces random noise on a given
%       timestep.

% Output:
%   tp - maximum obtainable cell true positive rate. Scalar
%   fp - corresponding false positive rate. Scalar
%   cellROC - cell ReceiverOperatingCharacteristic object
%   sensorTP - sensor true positive rate used to obtain cell ROC curve
%   sensorFP - sensor false positive rate used to obtain cell ROC curve

%
import aggregate.*
import roc.*
import check.*

if(nargin == 4)
   faultRate = 0; 
end
    
assert(isPositiveScalar(N));
N = floor(N); % make sure its an integer.

assert(isPositiveScalar(maxSensorFalsePositive));
assert(isPositiveScalar(maxCellFalsePositive));

% uniformly discretize the sensor ROC curve
nDiscretizations = 1000; % <== Magic Number

%fpDiscretize = linspace(0,1, nDiscretizations)'; % must be a column vector
fpDiscretize = logspace(-4,0, nDiscretizations)'; % must be a column vector
tpDiscretize = sensorROC.interpolateTruePositiveRate(fpDiscretize);


% for each admissible point on the sensor ROC curve, compute the cell ROC
% curve, and find the maximum true positive rate


cCellROC = cell(nDiscretizations,1);
cMaxCellTruePositive = cell(nDiscretizations,1);

for i=1:nDiscretizations
   %disp(i)
   sensorFalsePositiveRate = fpDiscretize(i); 
   sensorTruePositiveRate = tpDiscretize(i); 
   
   effectiveTp = (faultRate * 0.5) + (1-faultRate)*sensorTruePositiveRate;
   effectiveFp = (faultRate * 0.5) + (1-faultRate)*sensorFalsePositiveRate;
   
   if sensorFalsePositiveRate > maxSensorFalsePositive
      continue 
   end
   
   cellROC = computeCellROC(N, effectiveTp, effectiveFp);
   
   % assuming that true positive rate is monotonically increasing with
   % false positive rate
   
   maxCellTruePositive = cellROC.interpolateTruePositiveRate(maxCellFalsePositive);
   
   cCellROC{i} = cellROC;
   cMaxCellTruePositive{i} = maxCellTruePositive;
   
end

% find cell with maximum maxCellTruePositive. 
% NOTE: possible bug here if cCellROC is empty...
[maxCellTruePositive, I] = max(cell2mat(cMaxCellTruePositive));
cellROC = cCellROC{I};
%disp(I)

tp = maxCellTruePositive;
fp = maxCellFalsePositive;
sensorTP = tpDiscretize(I);
sensorFP = fpDiscretize(I);

% TODO check outputs
end

