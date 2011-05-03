%{

FILE: plot_multi_act_reduction1.m

USE: Plot the specified 3 dimensions of the first 6 activities. Must run 
     multi_act_reductionX.m first.

PARAMETERS:
    i, j, k: The three dimensions to plot.
%}

i = 1;
j = 2;
k = 3;

% 3D Plot.
subplot(2,2,1)
plot3(redudata{1}(:,i), redudata{1}(:,j),redudata{1}(:,k), '.r', ...
redudata{2}(:,i), redudata{2}(:,j),redudata{2}(:,k), '.g', ...
redudata{3}(:,i), redudata{3}(:,j),redudata{3}(:,k), '.b', ...
redudata{4}(:,i), redudata{4}(:,j),redudata{4}(:,k), '.c', ...
redudata{5}(:,i), redudata{5}(:,j),redudata{5}(:,k), '.k', ...
redudata{6}(:,i), redudata{6}(:,j),redudata{6}(:,k), '.m')

% 2D Projection on plane i, j
subplot(2,2,2)
plot(redudata{1}(:,i), redudata{1}(:,j), '.r', ...
redudata{2}(:,i), redudata{2}(:,j),'.g', ...
redudata{3}(:,i), redudata{3}(:,j),'.b', ...
redudata{4}(:,i), redudata{4}(:,j),'.c', ...
redudata{5}(:,i), redudata{5}(:,j),'.k', ...
redudata{6}(:,i), redudata{6}(:,j),'.m')

% 2D Projection on plane i, k
subplot(2,2,3)
plot(redudata{1}(:,i), redudata{1}(:,k), '.r', ...
redudata{2}(:,i), redudata{2}(:,k),'.g', ...
redudata{3}(:,i), redudata{3}(:,k),'.b', ...
redudata{4}(:,i), redudata{4}(:,k),'.c', ...
redudata{5}(:,i), redudata{5}(:,k),'.k', ...
redudata{6}(:,i), redudata{6}(:,k),'.m')

% 2D Projection on plane j, k
subplot(2,2,4)
plot(redudata{1}(:,j), redudata{1}(:,k), '.r', ...
redudata{2}(:,j), redudata{2}(:,k),'.g', ...
redudata{3}(:,j), redudata{3}(:,k),'.b', ...
redudata{4}(:,j), redudata{4}(:,k),'.c', ...
redudata{5}(:,j), redudata{5}(:,k),'.k', ...
redudata{6}(:,j), redudata{6}(:,k),'.m')
