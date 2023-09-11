% function [] = Fig2Gen(data_dir)
% generates English et al., paper Fig 2
% which contains a top subplot of a keogram of 01/01/2014,
% slices of intensity vs elevation at 04:00, 08:30, and 12:30 UT, 
% and histograms of intensity at each of those Keogram Time Intervals
function [] = Fig2Gen(data_dir)

% Load data created by P2*.m
disp('Loading KeogCloudData.mat')
load([data_dir filesep 'KeogCloudData.mat'])
disp('Loaded')

% Select date of interest
TargetDate = datetime(2014, 1, 1); %2/21/2014 14 UT, 2/22/2014
TargetDateandTime = datetime(2014, 1, 1, 14, 0, 0);

%%
% Select the data corresponding to the date.
KeogIndex = find(NDate == TargetDate);
% Convert data from cell to numeric array.
KeogFFC = NFFC{KeogIndex};
% Select the greenline intensities.
KeogFFC_557 = KeogFFC(:,4,:);

% Convert the seconds of day into decimal hour.
Time = NTimeSeconds{KeogIndex}./3600;

% Extract the coefficient of variation and convert from cell to array.
cv_FFC = Ncv_FFC{KeogIndex};
cv_557FFC = cv_FFC(4, :);

% Extract the standard deviation and convert from cell to array.
std_FFC = Nstd_FFC{KeogIndex};
std_557FFC = std_FFC(4, :);

% Extract the average greenline intensity and convert from cell to array.
avg = NAvgIntensity{KeogIndex};
avg_557 = avg(4,:);

% Select 04:00 UT.
timelist = [4; 8.5; 13.5];
for list_ind = 1:numel(timelist)

    % Find data corresponding to the timestamp of interest.
    index(list_ind) = find(abs(Time-timelist(list_ind)) == ...
	min(abs(Time - timelist(list_ind))));
    cv(list_ind) = cv_557FFC(index(list_ind));
    std(list_ind) = std_557FFC(index(list_ind));
    avg(list_ind) = avg_557(index(list_ind));
end
%Time2 = 8.5;%+(29/60); 
%index2 = find(abs(Time-Time2) == min(abs(Time - Time2)));
%cv2 = cv_557FFC(index2);
%std2 = std_557FFC(index2);
%avg2 = avg_557(index2);

%Time3 = 13.5; 
%index3 = find(abs(Time-Time3) == min(abs(Time - Time3)));
%cv3 = cv_557FFC(index3);
%std3 = std_557FFC(index3);
%avg3 = avg_557(index3);

% Initialize figure and subplots.
f1 = figure; figure(f1);
subplot(3, 3, [1 2 3]);

theta = [10:170]; %10:10:170
% Fig a) plot the keogram.
imagesc(Time, theta, squeeze(KeogFFC_557));
if verLessThan('matlab', 'R2016b')
	set(gca, 'XTick', [floor(min(Time)):1:floor(max(Time))])
else
	xticks([floor(min(Time)):1:floor(max(Time))])
end
hold on;
ax = axis;
xlabel('UT Hour')

% Mark the three times whose histograms will be shown with vertical lines.
xcoords = repmat(Time(index),1,2);
ycoords = repmat(ax(3:4), 3, 1);
h = plot(xcoords', ycoords', 'm-');
set(h, 'LineWidth', 2)
title(['a) 557.7 nm Keogram ' datestr(TargetDate, 'mmm dd, yyyy')])%Jan 1 2014');
ylabel('Elevation Angle \newline along the meridian \newline [\theta from N]');
a = colorbar;
ylabel(a, 'Intensity [Rayleighs]');
clims = caxis;
caxis([0 clims(2)*.50]);
% Mark the intervals with boxes and labels. 
xboxlim = {[Time(1) 5.125 5.125 Time(1) Time(1)];
	[8 10 10 8 8];
	[11.5 15.5 15.5 11.5 11.5]};
yboxlim = [ax(3) ax(3) ax(4) ax(4) ax(3)];
for list_ind = 1:numel(timelist)
    h = plot(xboxlim{list_ind}, yboxlim, 'w');
    set(h, 'LineWidth', 4)
    texth = text(xboxlim{list_ind}(2)-1.9, yboxlim(1)+20, ['Interval ' num2str(list_ind)]);
    set(texth, 'Color','w', 'FontWeight', 'Bold', 'FontSize', 16)
end

% For Figs b,d,f, set the maximum intensity for all y-axes.
ymax = max(max(squeeze(KeogFFC_557(:,:,index)))) + 100;

% Figure b-d intensity vs elevation at the 3 selected times.
prefixstr = {'b) Dark Sky ', 'd) Clear Sky ', 'f) Cloudy Sky '};
for list_ind = 1:numel(timelist)
    subplot(3, 3, list_ind+3); %intensity vs viewing angle for time 1
    plot(theta, KeogFFC_557(:, :, index(list_ind)));
    title([prefixstr{list_ind} datestr(datenum(TargetDate) + ...
    timelist(list_ind)/24, 'HH:MM UT')]);
    ylim([0 ymax]);
    ylabel('Intensity [Rayleighs]');
    xlabel('Elevation Angle [\theta from N]');

end



xbins = 0:7.5e2:3e4;%500:20000;

prefixstr = {'c) Dark Sky ', 'e) Clear Sky ', 'g) Cloudy Sky '};
for list_ind = 1:numel(timelist)
    subplot(3, 3, list_ind+6); %histogram time 1
    hist(KeogFFC_557(:, :, index(list_ind)), xbins);
    ylim([0 70]);
    xlim([0 30000]);
    % set(gca, 'YScale', 'log')
    text(10000, 50, ['\sigma = ' num2str(round(std(list_ind)))]);
    text(10000, 40, ['\mu = ' num2str(round(avg(list_ind)))]);
    title([prefixstr{list_ind} 'Histogram '... 
datestr(datenum(TargetDate) + ...
    timelist(list_ind)/24, 'HH:MM UT')]);
    ylabel('Frequency [count]');
    xlabel('Intensity [Rayleighs]');
end

