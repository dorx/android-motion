function [ cellTP, cellFP, sensorTP, sensorFP, cCellROC ] = ...
    cellPerformanceVsDensity( sensorROC, sfpMax, cfpMax, sensorCount, faultRate)
% cellPerformanceVsDensity - obtainable cell TP, vs number of sensors
%   
% Input:
%   sensorROC - sensor ReceiverOperatingCharacteristic object
%   sfpMax - maximum allowed sensor false positive rate
%   cfpMax - maximum allowed cell false positive rate
%   nSensors - vector. Each element is the number of sensors in cell.
%
% Output:
%   cellTP - maximum obtainable cell true positive rates.
%   cellFP - corresponding cell false positive rates.
%   sensorTP - corresponding sensor true positive rates.
%   sensorFP - corresponding sensor false positive rates.
%   cCellROC - cell ROC curves for each value of sensorCount.
%

import roc.*
import check.*

if nargin == 4
    faultRate = 0;
end

nValues = length(sensorCount);

cellTP = zeros(nValues,1);
cellFP = zeros(nValues,1);
 
sensorTP = zeros(nValues,1);
sensorFP = zeros(nValues,1);

cCellROC = cell(nValues,1);

% parallelize?
parfor i=1:nValues
   import aggregate.* % not sure why this is needed 
    
    n = sensorCount(i);
    
    [ ctp, cfp, cellROC, stp, sfp] = ...
        optimizeCellTruePositive( n, sensorROC, sfpMax, cfpMax, faultRate );
    
    cellTP(i) = ctp;
    cellFP(i) = cfp;
    
    sensorTP(i) = stp;
    sensorFP(i) = sfp;
    
    cCellROC{i} = cellROC;
end

end

