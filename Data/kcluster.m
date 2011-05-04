function [ InError, OutError, centers ] = kcluster(trainset, trainlabel, testset, testlabel)
%{
%   Detailed explanation goes here
%}

k = 2;

[classes, centers, fdistance] = dcKMeans(trainset, k);

skip = 0;


% Find which center correspond to which trainlabel.

% First find the average distance to center from fdistance
avgDist = sum(fdistance) / length(fdistance);

% Check the labels within (0.5 * avgDist)
cutoffDistSq = (avgDist/2)^2;
label = zeros(k, 1);
for icenter = 1 : k
    
    total_label = 0;
    count = 0;
    
    for pt = 1 : length(trainset)
        %trainset(pt,:)
        %centers(icenter,:)
        distToCenterSq = sum((trainset(pt, :) - centers(icenter, :)).^2);
        
        if distToCenterSq < cutoffDistSq
            total_label = total_label + trainlabel(pt);
            count = count + 1;
        end
        
        label(icenter,1) = int32(total_label / count);
    end

end


% Check that all centers have different labels
for icenter = 1 : k
    for jcenter = 1 : k
        
        if icenter == jcenter
            continue;
        end
        
        if label(icenter,1) == label(jcenter,1)
            InError = 1
            OutError = 1
            skip = 1;
            break;
            %printplots();
            
            %error('Two centers have the same label. Mission aborted.')
        end
        
    end
    
    if skip == 1
        break
    end
    
end

if skip == 0
% Change the labels in classes to match the found *labels*
for pt = 1 : length(trainset)
    
    % This is the same as the index for the closest center
    original_label = classes(pt);           
    % Find the center's new label to pt
    new_label = label(original_label);         
    
    classes(pt) = new_label;                % Assign new label.
end

% Find in-sample error InError (each point is assigned 1 or 2 in classes)
InError = sum(abs(classes - trainlabel)) / length(trainlabel)


% Find out-of-sample error
classified = zeros(length(testlabel),1);
nerr = 0;
for pt = 1 : length(testset)
   
    coord = testset(pt,:);
    closestCent = 1;
    distSq = sum((coord - centers(1,:)).^2);
    
    % Find the closest center
    for icenter = 2 : k,
        
        tempDistSq = sum((coord - centers(icenter)).^2);
        
        if tempDistSq < distSq
            distSq = tempDistSq;
            closestCent = icenter;
        end
        
    end

    classified(pt) = label(closestCent);
end

% Assuming labels to be differ by one
OutError = sum(abs(classified - testlabel)) / length(testlabel)

end % end if

    function [] = printplots()
        
        actmat1 = [];
        actmat2 = [];
        
        for i = 1 : length(trainset)
            if trainlabel(i) == 1
                actmat1 = vertcat(actmat1, trainset(i,:));
            else
                actmat2 = vertcat(actmat2, trainset(i,:));
            end
        end
        
        trainlabel
                    
        plot3(actmat1(:,1), actmat1(:,2), actmat1(:,3), '.b',...
            actmat2(:,1), actmat2(:,2), actmat2(:,3), '.r',...
            centers(:,1), centers(:,2), centers(:,3), '.k');
        
    end

end
