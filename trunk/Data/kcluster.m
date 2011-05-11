function [ InError, OutError, centers ] = kcluster(trainset, trainlabel, testset, testlabel)
%{
%   Detailed explanation goes here
%}

k = 2;

[classes, centers, fdistance] = dcKMeans(trainset, k);

skip = 0;


% Find which center correspond to which trainlabel.

% Split trainset into trainset0 and trainset1
trainset0 = [];
trainset1 = [];
for i = 1 : length(trainset)
    if trainlabel(i) == 0
        trainset0 = vertcat(trainset0, trainset(i, :));
    else
        trainset1 = vertcat(trainset1, trainset(i, :));
    end
end

% Make sure that two activities have the same number of training data.
assert(size(trainset0, 1) == size(trainset1, 1));

% Find the corresponding center for each trainset.
label = zeros(k, 1);
train0toc1 = sum((trainset0 - centers(1)).^2);
train0toc2 = sum((trainset0 - centers(2)).^2);
if train0toc1 < train0toc2
    label(1) = 0;
else
    label(2) = 0;
end

train1toc1 = sum((trainset1 - centers(1)).^2);
train1toc2 = sum((trainset1 - centers(2)).^2);
if train1toc1 < train1toc2
    label(1) = 1;
else
    label(2) = 1;
end


%{
% First find the average distance to center from fdistance
avgDist = sum(fdistance) / length(fdistance);

% Check the labels within (certain cutoffDistSq)
cutoffDistSq = (avgDist/2)^2;
label = zeros(k, 1);
for icenter = 1 : k
    
    total_label = 0;
    count = 0;
    
    for pt = 1 : length(trainset)
        
        distToCenterSq = sum((trainset(pt, :) - centers(icenter, :)).^2);
        
        if distToCenterSq < cutoffDistSq
            %display(trainlabel(pt));
            %display(' is counted to center ');
            %display(icenter);
            total_label = total_label + trainlabel(pt);
            count = count + 1;
        end
        
        label(icenter,1) = int32(total_label / count);
    end

end

%trainlabel

%cutoffDistSq
%centers
%label
%}


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
            printplots();
            break;
            
            
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

    function printplots()
        
        %actmat1 = [0 0 0];
        %actmat2 = [0 0 0];
        actmat1 = [];
        actmat2 = [];
        
        for i = 1 : length(trainset)
            if trainlabel(i) == 1
                actmat1 = vertcat(actmat1, trainset(i,:));
            else
                actmat2 = vertcat(actmat2, trainset(i,:));
            end
        end
                    
        plot3(actmat1(:,1), actmat1(:,2), actmat1(:,3), '.b',...
            actmat2(:,1), actmat2(:,2), actmat2(:,3), '.r',...
            centers(:,1), centers(:,2), centers(:,3), '.c');
        
    end

end
