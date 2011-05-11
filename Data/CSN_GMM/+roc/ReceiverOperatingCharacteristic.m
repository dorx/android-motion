classdef ReceiverOperatingCharacteristic
    % ReceiverOperatingCharacteristic
    %   ROC curve
    %
    % author: Matt Faulkner
    %
    
    % ===================================================================
    
    properties
        truePositiveRates   % column vector
        falsePositiveRates  % column vector
        thresholds          % possibly empty
    end
    
    % ===================================================================
    
    methods
        
        % ---------------------------------------------------------------
        
        function obj = ReceiverOperatingCharacteristic(tp, fp, thresholds)
           %  constructor
           % Input:
           %    tp - column vector of true positive rates, each in [0,1]
           %    fp - column vector of false positive rates, each in [0,1]
           %    thresholds - (optional) threshold values used to produce tp, fp 
           import roc.*
           import check.*
           
           assert(isColumnVector(tp));
           assert(isColumnVector(fp));
           

           % make sure that (0,0) and (1,1) are included
           fp = [0; fp; 1];
           tp = [0; tp; 1];
           
           m = [fp, tp];
           [m, I] = unique(m, 'rows'); % remove duplicate points and sort
           fp = m(:,1);
           tp = m(:,2);
           
           
           if nargin == 3
               % save corresponding thresholds. This has not been
               % thoroughly tested, as of Oct. 28
               
               % edge-extend
               thresholds = [thresholds(end); thresholds; thresholds(1)]; % < ---------- look here
               
               assert(isColumnVector(thresholds));
               thresholds = thresholds(I);
           else
               thresholds = {};
           end
           
           obj.falsePositiveRates = fp;
           obj.truePositiveRates = tp;
           obj.thresholds = thresholds;
           
           assert(isColumnVector(obj.falsePositiveRates));
           assert(isColumnVector(obj.truePositiveRates));
           
           % TODO: check that the tp, fp values are in [0,1]
           
        end
        
        % ---------------------------------------------------------------
        
        function obj = convexHull(obj)
           % Compute the convex hull of the ROC.
           % NOTE: this hasn't really been tested, so might not actually
           % copute the convex hull...
           
           % The naive n^3 version:
           % assume n (x,y) points
           % for each point i,
           %    for each point j
           %        find the indices in [i+1, j-1] that are below the 
           %        line from i to j
           %    end
           % end
           %
           % remove all points that were found below a line
           
           n = length(obj.truePositiveRates);
           y = obj.truePositiveRates;
           x = obj.falsePositiveRates;
           badIndices = [];
           for i=1:n;
               if any(ismember(badIndices,i))
                   continue
               end
               for j=1:n;
                   if any(ismember(badIndices,j))
                       continue
                   end
                    for k=i+1:j-1
                        % slope of pi, pj
                        m = (y(j) - y(i)) / (x(j) - x(i));
                        
                        lineVal = m * (x(k) - x(i));
                        if (y(k) < lineVal)
                           badIndices =  unique([badIndices, k]);
                        end
                    end
               end
           end
           
           badIndices = unique(badIndices);
           x(badIndices) = [];
           y(badIndices) = [];
           obj.falsePositiveRates = x;
           obj.truePositiveRates = y;
           

        end
        
        % ---------------------------------------------------------------
        
        function area = areaUnderCurve(obj)
            % Compute the area under the curve
            import roc.*
            area = auc(obj.falsePositiveRates, obj.truePositiveRates);
            
            % TODO: error or warning if area is not in [0,1]
            
        end
        
        % ---------------------------------------------------------------
        
        % TODO: max true positive rate, given constraint on false positive
        % rate
        
        % ---------------------------------------------------------------
        

        % ---------------------------------------------------------------
        
        function [tp_interp, thresh_interp ]= interpolateTruePositiveRate(obj, fp_interp)
           % get the true positive rates via linear interpolation that
           % correspond to the specified false positive rates
           %
           % Input:
           %    fp_interp - false positive rates. Column vector
           %
           % Output:
           %    tp_interp - interpolated true positive rates. Column
           %        vector.
           %    thresh_interp - corresponding threshold, possibly empty
           %
           import roc.*
           import check.*
           
           assert(isColumnVector(fp_interp));
           
           TPR = obj.truePositiveRates;
           FPR = obj.falsePositiveRates;
           
           % deal with non-unique values:
           [FPR_unique, I] = unique(FPR);
           TPR_unique = TPR(I);
           
           % perform linear interpolation
           %tp_interp = interp1(FPR, TPR, fp_interp);
           tp_interp = interp1(FPR_unique, TPR_unique, fp_interp);
           
           assert(isColumnVector(tp_interp));
           
           thresh_interp = {};
           if ~isempty(obj.thresholds)
               thresholds_unique = obj.thresholds(I);
               % remove any NaNs from thresholds, and also from the frp
               nanIndices = isnan(thresholds_unique);
               thresholds_unique(nanIndices) = [];
               FPR_unique(nanIndices) = [];
               thresh_interp = interp1(FPR_unique, thresholds_unique, fp_interp);
           end
           
        end
        
        % ---------------------------------------------------------------
        
    end
    
    % ===================================================================
    
    methods(Static)
        
        % ---------------------------------------------------------------        
        
        function plot(obj, varargin)
            % Not sure if this should be static. Also, overloading like
            % this might not work with Matlab prior to R2010b
            % 
            % standard ROC plot
            plot(obj.falsePositiveRates, obj.truePositiveRates, varargin{:})
            axis([0,1,0,1])
        end
        
        % ---------------------------------------------------------------        
        
    end
    
    % ===================================================================
    
end

