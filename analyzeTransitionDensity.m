function tdp = analyzeTransitionDensity()
% author: Sriram Tiruvadi Krishnan Ph.D. at Dr. Rajan Lamichhane lab
% date of last commit: 01/12/2023
% This code is used to generate and to perform the Transition density plots
% Input data is the output files '*report.dat' of the HaMMy fitting tool

close all;
norm_factor = 4; % for PIFE data it is usually 4; for FRET it is 1;
figTitle = 'TDP';
reportsPath = uigetdir(['Select the directory containing',...
    ' the reports data files']);
if ~reportsPath
    return;% user pressed cancel button.
end
cd(reportsPath);
outPath = [reportsPath, filesep, 'Results'];
if 7 == exist(outPath, 'dir')
    rmdir(outPath, 's');
end
mkdir(outPath);

outPath = [outPath, filesep];
reportsList = dir('*.dat');
reportsName = {reportsList.name};

for i = 1:length(reportsName)
    filePathName = strcat(reportsPath, filesep,...
        string(reportsName(i)));
    delimiterIn = ' ';
    headerlinesIn = 4;
    tempData = importdata(filePathName,delimiterIn,headerlinesIn);
    
    if i==1
        data = tempData.data;
    else
        data = [data;tempData.data];
    end
end
initial = times(data(:,1), norm_factor);
final = times(data(:,2), norm_factor);
counts = data(:,5);

mainData(:,1) = initial(counts>0);
mainData(:,2) = final(counts>0);
mainData(:,3) = counts(counts>0);

count_transitions = sortrows(mainData,1);
cntTransFile = [outPath, 'transition_count.txt'];
save(cntTransFile, 'count_transitions', '-ascii', '-tabs');

transitions = [];
for i = 1:length(mainData)
    tempTrans = [times(ones(mainData(i,3),1), mainData(i,1)),...
        times(ones(mainData(i,3),1), mainData(i,2))];
    transitions = [transitions; tempTrans];
end

minval = 0;
maxval = 1*norm_factor;
pts = 100;

X = linspace(minval, maxval, pts)';
Y = X';
%generate start and stop vectors
start = transitions(:, 1);
stop = transitions(:, 2);

var = (norm_factor^2)/(4^3*10);

%generate 2D transition histogram
for j = (1:pts)
    for i = (1:pts)
        A = abs(X(i) - start);
        B = abs(Y(j) - stop);
        Z(j, i) = sum(exp(-(A.^2 + B.^2)/(2*var)));
    end
end

%apply interpolation
%set axis limits -0.2-1.2 or 0-1
XI = linspace(minval, maxval, 10*pts);
ZI = interp2(X, Y, Z, XI', XI, 'cubic');

ticks = linspace(minval, maxval, 5);
hold on
tdp = pcolor(XI', XI, ZI);
xticks(ticks)
yticks(ticks)
box off
grid on
line([maxval minval], [maxval maxval], 'Color','k', 'LineWidth', 1.5);
line([maxval maxval], [minval maxval], 'Color','k', 'LineWidth', 1.5);
set(gca,'layer','top', 'GridLineStyle','--', 'TickDir','out',...
    'FontSize', 16, 'FontName','Arial','FontWeight','Bold',...
    'LineWidth', 1.5)
colormap(viridis_stk(256))
shading interp
axis square tight
% add plot labels
xlabel('Initial Intensity', 'FontSize', 16, 'FontName','Arial',...
    'FontWeight', 'Bold');
ylabel('Final Intensity','FontSize', 16, 'FontName','Arial',...
    'FontWeight', 'Bold');
title(figTitle,'FontSize', 18, 'FontName','Arial','FontWeight', 'Bold');
c = colorbar();
c.Label.String = 'density';
c.Label.FontSize = 16;
c.Label.FontName = 'Arial';
c.Label.FontWeight = 'Bold';
c.LineWidth = 1.5;
c.TickLabels = [];
c.TickDirection = 'out';

t = annotation('textbox');
t.String = ['N = ',int2str(length(transitions))];
t.FontSize = 12;
t.FontName = 'Arial';
t.FontWeight = 'Bold';
t.LineStyle = 'none';
t.Position = [0.6 0.15 0.1 0.1];
hold off
saveas(gcf,[outPath,figTitle,'_TDP'],'fig');
end
