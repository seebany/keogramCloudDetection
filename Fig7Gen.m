% function [] = Fig7Gen(data_dir)
% generates English et al., paper Fig 6
% which contains a top subplot of a keogram of 01/21/2014,
% slices of intensity vs elevation at 09:00, and 11:00 UT, 
% and histograms of intensity at each of those Keogram Time Intervals
function [] = Fig7Gen(data_dir)

% Load data created by P2*.m
disp('Loading KeogCloudData.mat')
load([data_dir filesep 'KeogCloudData.mat'])
disp('Loaded')

TargetDate = datetime(2014, 2, 21); %2/21/2014 14 UT, 2/22/2014
TargetDateandTime = datetime(2014, 2, 21, 14, 0, 0);

%%
KeogIndex = find(NDate == TargetDate);
KeogFFC = NFFC{KeogIndex};
KeogFFC_557 = KeogFFC(:,4,:);
Time = NTimeSeconds{KeogIndex}./3600;
cv_FFC = Ncv_FFC{KeogIndex};
std_FFC = Nstd_FFC{KeogIndex};
cv_557FFC = cv_FFC(4, :);
std_557FFC = std_FFC(4, :);
avg = NAvgIntensity{KeogIndex};
avg_557 = avg(4,:);

% Select 9 UT and 11 UT
timelist = [9; 11]; % UT hour
%Time1 = 9;
for list_ind = 1:numel(timelist)
    % Find data corresponding to the timestamp of interest.
    index(list_ind) = find(abs(Time-timelist(list_ind)) == ...
	min(abs(Time - timelist(list_ind))));
    cv(list_ind) = cv_557FFC(index(list_ind));
    std(list_ind) = std_557FFC(index(list_ind));
    avg(list_ind) = avg_557(index(list_ind));
end

%---------------------------------------------------------
f1 = figure; figure(f1);
subplot(4, 2, [1 2]);
theta = [10:170];
imagesc(Time, 10:10:170, squeeze(KeogFFC_557));
if verLessThan('matlab', 'R2016b')
	set(gca, 'XTick', [floor(min(Time)):1:floor(max(Time))])
else
	xticks([floor(min(Time)):1:floor(max(Time))])
end
hold on;
ax = axis;
%xlabel('UT Hour')

% Mark the times whose histograms will be shown with vertical lines.
xcoords = repmat(Time(index),1,2);
ycoords = repmat(ax(3:4), numel(timelist), 1);
h = plot(xcoords', ycoords', 'm-');
set(h, 'LineWidth', 2)
title(['a) 557.7 nm Keogram ' datestr(TargetDate, 'mmm dd, yyyy') ' vs UT Hour'])%Jan 1 2014');
ylabel('Elevation Angle \newline along the meridian \newline [\theta from N]');
a = colorbar;
ylabel(a, 'Intensity [Rayleighs]');
clims = caxis;
caxis([0 clims(2)*.30]);

%plot([Time(index1) Time(index1)], [10 170], 'r-');
%plot([Time(index2) Time(index2)], [10 170], 'r-');
%title('a) 557 nm Keogram Feb 21 2014');
%ylabel('Viewing Angle [\theta from N]');
%colorbar;
%clims = caxis;
%caxis([0 clims(2)*.30]);
%
%ymax = max([max(KeogFFC_557(:, :, index2)) max(KeogFFC_557(:, :, index1))]) + 1000;

%---------------------------------------------------------
% For Figs c-d, set the maximum intensity for all y-axes.
ymax = max(max(squeeze(KeogFFC_557(:,:,index)))) + 100;
prefixstr = {'c) Discrete Aurora ', 'e) Diffuse Aurora '};

subplot(4, 2, [3 4]);
h = plot(Time, [cv_557FFC; ones(size(cv_557FFC))*0.25], 'HandleVisibility','off');
hold on;
axis tight;
ax = axis;
axis([ax(1:2), 0 2]);
ax = axis;
ycoords = repmat(ax(3:4), numel(timelist), 1);
legend(h, 'Coefficient of variation', 'Cloud Threshold', 'Location','Best');
h = plot(xcoords', ycoords', 'm-');
set(h, 'LineWidth', 2)
%plot([Time(index1) Time(index1)], [0 max(cv_557FFC)], 'r-', 'HandleVisibility','off');
%plot([Time(index2) Time(index2)], [0 max(cv_557FFC)], 'r-', 'HandleVisibility','off');
%% text(Time(index1), max(cv_557FFC), '9 UT');
%% text(Time(index2), max(cv_557FFC), '11 UT');
%plot([min(Time) max(Time)], [0.51 0.51], '-g', 'DisplayName', 'CoV Cloud Threshold');
if verLessThan('matlab', 'R2016b')
	set(gca, 'XTick', [floor(min(Time)):1:floor(max(Time))])
else
	xticks([floor(min(Time)):1:floor(max(Time))])
end

title('b) Coefficient of Variation');
ylabel('Coefficient of Variation');
xlabel('UT Hour')

%---------------------------------------------------------
%subplot(5, 2, [5 6]);
%plot(Time, std_557FFC, 'HandleVisibility','off');
%hold on;
%plot([Time(index1) Time(index1)], [0 max(std_557FFC)], 'r-', 'HandleVisibility','off');
%plot([Time(index2) Time(index2)], [0 max(std_557FFC)], 'r-', 'HandleVisibility','off');
%% text(Time(index1), max(cv_557FFC), '9 UT');
%% text(Time(index2), max(cv_557FFC), '11 UT');
%% plot([min(Time) max(Time)], [0.51 0.51], '-g', 'DisplayName', '\sigma Cloud Threshold');
%indexCF = find(cv_557FFC < 0.51);
%plot(Time(indexCF), std_557FFC(indexCF), '.g','LineWidth',2, 'DisplayName', 'CoV < 0.51');
%xticks([floor(min(Time)):1:floor(max(Time))])
%title('c) Standard Deviation');
%ylabel('Standard Deviation [\sigma]');
%% legend();
%xlabel('Time [UTC]');

%---------------------------------------------------------
for list_ind = 1:numel(timelist)
    subplot(4, 2, list_ind+4); %intensity vs viewing angle for time 1
    plot(theta, KeogFFC_557(:, :, index(list_ind)));
    title([prefixstr{list_ind} datestr(datenum(TargetDate) + ...
    timelist(list_ind)/24, 'HH:MM UT')]);
    ylim([0 ymax]);
    ylabel('Intensity [Rayleighs]');
    xlabel('Elevation Angle [\theta from N]');

end

%---------------------------------------------------------
xbins = 0:500:20000;
prefixstr = {'d) Discrete Aurora Histogram ', 'f) Diffuse Aurora Histogram '};%, 'g) Cloudy Sky '};
for list_ind = 1:numel(timelist)
    subplot(4, 2, list_ind+6); %histogram time 1
    hist(KeogFFC_557(:, :, index(list_ind)), xbins);
    ylim([0 70]);
    xlim([0 20000]);
    % set(gca, 'YScale', 'log')
    text(10000, 50, ['\sigma = ' num2str(round(std(list_ind)))]);
    text(10000, 40, ['\mu = ' num2str(round(avg(list_ind)))]);
    title([prefixstr{list_ind} 'Histogram '... 
datestr(datenum(TargetDate) + ...
    timelist(list_ind)/24, 'HH:MM UT')]);
    ylabel('Frequency [count]');
    xlabel('Intensity [Rayleighs]');
end

%subplot(5, 2, 9); %histogram time 1
%hist(KeogFFC_557(:, :, index1), xbins);
%ylim([0 70]);
%xlim([0 20000]);
%% set(gca, 'YScale', 'log')
%text(10000, 50, ['\sigma = ' num2str(std1)]);
%text(10000, 40, ['\mu = ' num2str(avg1)]);
%title('Aurora Histogram 9 UT');
%ylabel('f) Frequency [count]');
%xlabel('Intensity [Rayleighs]');
%
%subplot(5, 2, 10); %histogram time 1
%hist(KeogFFC_557(:, :, index2), xbins);
%ylim([0 70]);
%xlim([0 20000]);
%% set(gca, 'YScale', 'log')
%text(10000, 50, ['\sigma = ' num2str(std2)]);
%text(10000, 40, ['\mu = ' num2str(avg2)]);
%%title('g) Diffuse Aurora Histogram 11 UT');
%ylabel('Frequency [count]');
%xlabel('Intensity [Rayleighs]');




