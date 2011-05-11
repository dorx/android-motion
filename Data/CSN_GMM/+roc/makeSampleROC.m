%% Make a generic ROC curve plot

muPositive =0.7;
n = 10000;

%positives = rand(n,1) + offset;
%negatives = rand(n,1);

positives = normrnd(muPositive, 1, n, 1);
negatives = normrnd(0,1,n,1);

Assignments = [positives; negatives];
TrueLabels = [ones(n,1); ones(n,1)*2 ];
Thresholds = linspace(min(Assignments), max(Assignments), 1000);

[TPR, FPR] = myROC(TrueLabels, Assignments, Thresholds);

%figure()
hold on
p = plot(FPR, TPR);
grid on

h = get(gca, 'title');
set(h, 'FontSize', 16)
set(p,'LineWidth',2)
set(gca, 'FontSize', 16)
%set(gca, 'xtick', [0,1], 'xticklabel', [0,1], 'ytick', [0,1], 'yticklabel', [0,1]);

%xlabel('False Positive Rate')
%ylabel('True Positive Rate')

%% An ugly ROC


y = [0,0.44, 0.5, 0.6, 0.66, 0.75,0.80, .9, .98, .99, 1];
x = linspace(0,1,length(y));

figure()
p = plot(x,y, '-o');
grid on
h = get(gca, 'title');
set(h, 'FontSize', 16)
set(p,'LineWidth',2)
set(gca, 'FontSize', 16)