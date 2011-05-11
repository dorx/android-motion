%clear all; % cleans up all variables
close all; % closes all figures
clc; % clean up the command window too


possibleActs = ['walking   ';
                'running   ';
                %'sitting   ';
                'idling    ';
                %'upstairs  ';
                %'downstairs';
                'biking    '];
possibleActs = cellstr(possibleActs);

rootDir = 'SensorRecordings';

nacts = length(possibleActs);

confusionM = zeros(nacts);

for i=1:nacts
    for j=1:nacts
        
        if i == j
            continue
        end
    
        % ntrain1 : number of data in training set TRAIN{i}
        % ntrain2 : number of data in training set TRAIN{j}
        % ntest1 : number of data in training set TEST{i}
        % ntest2 : number of data in training set TEST{j}
        % nfeatures : unused variable
        ntrain1 = size(TRAIN{i}, 1);
        ntrain2 = size(TRAIN{j}, 1);
        ntest1  = size(TEST{i} , 1);
        ntest2  = size(TEST{j} , 1);
        
        % To avoid bias, make trainset to have equal amount of act1 and
        %   act2. Test set does not have this constraint.
        ntrain = min(ntrain1, ntrain2);
        trainset = [TRAIN{i}(1:ntrain, :); TRAIN{j}(1:ntrain, :)];
        testset = [TEST{i}; TEST{j}];
        
        % Label act1 as 0, act2 as 1.
        trainlabel = [zeros(ntrain, 1); ones(ntrain, 1)];
        testlabel = [zeros(ntest1, 1); ones(ntest2, 1)];
        
        % Check the sizes of labels and data match.
        assert(size(trainlabel, 1) == 2 * ntrain);
        assert(size(testlabel, 1)  == ntest1 + ntest2);
        
        % Apply classification algorithm here.
        [InError, OutError, centers] = ...
            kcluster(trainset, trainlabel, testset, testlabel);

        confusionM(i, j) = OutError;
    end
end
