function plot_multi_act_PCA(DATA)
%{

FILE: plot_multi_act_PCA.m

USE: Plot the specified 3 dimensions of the input activity sets (up to 6)

PARAMETERS:
    act1~6: Activity matrices.

INTERNAL PARAMETERS
    i, j, k: The three dimensions to plot.
%}

close; % close all figures


% Plot the first component against 15 other compnents, resulting in 15
% plots (we place it on a 4 x 4 grid.
for iplot = 1 : 7

    subplot(4,2, iplot)

    ph = plot(  DATA{1}(:,iplot), DATA{1}(:,iplot + 1),'.r', ...
                DATA{2}(:,iplot), DATA{2}(:,iplot + 1),'.g', ...
                DATA{3}(:,iplot), DATA{3}(:,iplot + 1),'.k', ...                
                DATA{4}(:,iplot), DATA{4}(:,iplot + 1),'.c', 'MarkerSize',5);
        % other color choices: '.c', '.k', '.m'
end

% The last plot is the legend.
sh = subplot(4,2, 8);
p = get(sh,'position');
lh=legend(ph, 'walking', 'running', 'idling', 'biking');
set(lh,'position',p);
axis(sh,'off');

end

