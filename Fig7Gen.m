% function [] = Fig7Gen(data_dir)
% generates English et al., paper Fig 7
% which contains a top subplot of a keogram of 01/21/2014,
% slices of intensity vs elevation at 09:00, and 11:00 UT, 
% and histograms of intensity at each of those Keogram Time Intervals
%
% Created and run on Windows with Matlab R2019a.
% Tested on Linux Ubuntu with Matlab R2015b.
%
% This code assumes that P0*.m, P1*.m, P2*.m and P3*.m have already been
% run and the outputs stored.
%
% Created by Alex English 2022
% Documented and maintained by Seebany Datta-Barua
% Illinois Institute of Technology
% 25 Oct 2022
% License GNU GPL v3.
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
xlabel('UT Hour')

% Mark the times whose histograms will be shown with vertical lines.
xcoords = repmat(Time(index),1,2);
ycoords = repmat(ax(3:4), numel(timelist), 1);
h = plot(xcoords', ycoords', 'm-');
set(h, 'LineWidth', 2)
title(['a) 557.7 nm Keogram ' datestr(TargetDate, 'mmm dd, yyyy')])%Jan 1 2014');
ylabel('Elevation Angle \newline along the meridian \newline [\theta from N]');
a = colorbar;
ylabel(a, 'Intensity [Rayleighs]');
clims = caxis;
caxis([0 clims(2)*.30]);

%---------------------------------------------------------
% For Figs c-d, set the maximum intensity for all y-axes.
ymax = max(max(squeeze(KeogFFC_557(:,:,index)))) + 100;
prefixstr = {'c) Discrete Aurora ', 'e) Diffuse Aurora '};

subplot(4, 2, [3 4]);
h = plot(Time, [cv_557FFC; ones(size(cv_557FFC))*0.51], 'HandleVisibility','off');
hold on;
axis tight;
ax = axis;
ycoords = repmat(ax(3:4), numel(timelist), 1);
legend(h, 'Coefficient of variation', 'Cloud Threshold', 'Location','Best');
h = plot(xcoords', ycoords', 'm-');
set(h, 'LineWidth', 2)

if verLessThan('matlab', 'R2016b')
	set(gca, 'XTick', [floor(min(Time)):1:floor(max(Time))])
else
	xticks([floor(min(Time)):1:floor(max(Time))])
end

title('b) Coefficient of Variation');
ylabel('Coefficient of Variation [CoV]');
xlabel('UT Hour')


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





