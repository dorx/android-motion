function [] = plot_multi_act_reduction(act1, act2, act3, act4, act5, act6)
%{

FILE: plot_multi_act_reduction1.m

USE: Plot the specified 3 dimensions of the input activity sets (up to 6)

PARAMETERS:
    act1~6: Activity matrices.

INTERNAL PARAMETERS
    i, j, k: The three dimensions to plot.
%}

switch nargin
   
    case 2
        act3 = [];
        act4 = [];
        act5 = [];
        act6 = [];
    case 3
        act4 = [];
        act5 = [];
        act6 = [];
    case 4
        act5 = [];
        act6 = [];
    case 5
        act6 = [];
    
    otherwise
        error('Please supply 2~6 activities.')
end

i = 1;
j = 2;
k = 3;

% 3D Plot.
subplot(2,2,1)
plot3(act1(:,i), act1(:,j),act1(:,k), '.r', ...
act2(:,i), act2(:,j),act2(:,k), '.g', ...
act3(:,i), act3(:,j),act3(:,k), '.b', ...
act4(:,i), act4(:,j),act4(:,k), '.c', ...
act5(:,i), act5(:,j),act5(:,k), '.k', ...
act6(:,i), act6(:,j),act6(:,k), '.m')

% 2D Projection on plane i, j
subplot(2,2,2)
plot(act1(:,i), act1(:,j), '.r', ...
act2(:,i), act2(:,j),'.g', ...
act3(:,i), act3(:,j),'.b', ...
act4(:,i), act4(:,j),'.c', ...
act5(:,i), act5(:,j),'.k', ...
act6(:,i), act6(:,j),'.m')

% 2D Projection on plane i, k
subplot(2,2,3)
plot(act1(:,i), act1(:,k), '.r', ...
act2(:,i), act2(:,k),'.g', ...
act3(:,i), act3(:,k),'.b', ...
act4(:,i), act4(:,k),'.c', ...
act5(:,i), act5(:,k),'.k', ...
act6(:,i), act6(:,k),'.m')

% 2D Projection on plane j, k
subplot(2,2,4)
plot(act1(:,j), act1(:,k), '.r', ...
act2(:,j), act2(:,k),'.g', ...
act3(:,j), act3(:,k),'.b', ...
act4(:,j), act4(:,k),'.c', ...
act5(:,j), act5(:,k),'.k', ...
act6(:,j), act6(:,k),'.m')


end

