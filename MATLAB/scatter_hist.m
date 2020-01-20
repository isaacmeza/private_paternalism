%% Scatter histograms


%% Cost - Time
clear all
data = csvread('cost_time.csv');

Cost = data(:,1);
Time = data(:,2);

gcf = scatterhist(Cost,Time,'Kernel','on','Location', 'SouthEast',...
    'Direction','out','Color','kbr','LineStyle',{'-','-.',':'},...
    'LineWidth',[2,2,2],'Marker','+od','MarkerSize',[4,5,6]);

%% Financial Cost Survey - Admin
clear all
data = csvread('fc.csv');

Admin = data(:,1);
Subjective = data(:,2);

gcf = scatterhist(Admin,Subjective,'Kernel','on','Location', 'SouthEast',...
    'Direction','out','Color','kbr','LineStyle',{'-','-.',':'},...
    'LineWidth',[2,2,2],'Marker','+od','MarkerSize',[4,5,6]);

%% Financial Cost (log) Survey - Admin
clear all
data = csvread('logfc.csv');

Admin = data(:,1);
Subjective = data(:,2);

gcf = scatterhist(Admin,Subjective,'Kernel','on','Location', 'SouthEast',...
    'Direction','out','Color','kbr','LineStyle',{'-','-.',':'},...
    'LineWidth',[2,2,2],'Marker','+od','MarkerSize',[4,5,6]);
