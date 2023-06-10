% function [] = Fig3Gen(data_dir)
% generates English et al., paper Fig 3
% which contains a top subplot of a keogram of 01/01/2014,
% the keogram's standard deviation and mean vs time,
% and coefficient of variation vs time.
%
% Created and run on Windows with Matlab R2019a.
% Tested on Linux Ubuntu with Matlab R2015b.
%
% Created by Alex English 2022
% Documented and maintained by Seebany Datta-Barua
% Illinois Institute of Technology
% 25 Oct 2022
% License GNU GPL v3.

function [] = Fig3Gen(data_dir)
% Load data created by P2*.m
disp('Loading KeogCloudData.mat')
load([data_dir filesep 'KeogCloudData.mat'])
disp('Loaded')

TargetDate = datetime(2014, 1, 1); %2/21/2014 14 UT, 2/22/2014
TargetDateandTime = datetime(2014, 1, 1, 14, 0, 0);

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

f1 = figure; figure(f1);
subplot(3, 1, [1]);
imagesc(Time, 10:10:170, squeeze(KeogFFC_557));
if verLessThan('matlab', 'R2016b')
	set(gca, 'XTick', [floor(min(Time)):1:floor(max(Time))])
else
	xticks([floor(min(Time)):1:floor(max(Time))])
end
hold on
ax = axis;
xlabel('UT Hour')
title(['a) 557.7 nm Keogram ' datestr(TargetDate, 'mmm dd, yyyy')])%Jan 1 2014');
ylabel('Elevation Angle \newline along the meridian \newline [\theta from N]');
%a = colorbar;
%ylabel(a, 'Intensity [Rayleighs]');
clims = caxis;
caxis([0 clims(2)*.50]);

% Mark the intervals with boxes and labels. 
xboxlim = {[Time(1) 5.125 5.125 Time(1) Time(1)];
	[8 10 10 8 8];
	[11.5 15.5 15.5 11.5 11.5]};
yboxlim = [ax(3) ax(3) ax(4) ax(4) ax(3)];
for list_ind = 1:3%numel(timelist)
    h = plot(xboxlim{list_ind}, yboxlim, 'w');
    set(h, 'LineWidth', 4)
    texth = text(xboxlim{list_ind}(2)-1.75, yboxlim(1)+20, ['Interval ' num2str(list_ind)]);
    set(texth, 'Color','w', 'FontWeight', 'Bold', 'FontSize', 16)
end

subplot(3, 1, [2]);
%darkskyind = find(avg_557<500);
h = semilogy(Time, [std_557FFC; avg_557; 500*ones(size(avg_557))], '-', ...
'HandleVisibility','off');
legend([h], 'Standard deviation \sigma', 'Mean \mu', 'Dark sky cutoff', 'Location', 'NorthWest');
%Time(darkskyind), ones(length(darkskyind), 1)*1e4, ...

hold on
grid on
if verLessThan('matlab', 'R2016b')
	set(gca, 'XTick', [floor(min(Time)):1:floor(max(Time))])
else
	xticks([floor(min(Time)):1:floor(max(Time))])
end
%plot(Time(darkskyind), ones(length(darkskyind), 1)*10000, 'r.', 'DisplayName', 'Avg Intensity < 500 Rayleighs');
%plot(Time, avg_557, 'HandleVisibility','off');
axis tight
ax = axis;
%axis([Time(1) Time(end) ax(3:4)]);

yboxlim = [ax(3) ax(3) ax(4) ax(4) ax(3)];
title('b) Standard Deviation and Mean Intensity versus Time');
ylabel('Rayleighs');
xlabel('UT Hour')

for list_ind = 1:3%numel(timelist)
    h = plot(xboxlim{list_ind}, yboxlim, 'k');
    set(h, 'LineWidth', 4)
    texth = text(xboxlim{list_ind}(2)-1.75, yboxlim(1)+30, ['Interval ' num2str(list_ind)]);
    set(texth, 'Color','k', 'FontWeight', 'Bold', 'FontSize', 16)
end

%hold on;
%axis tight
%ax = axis;
%yboxlim = [ax(3) ax(3) ax(4) ax(4) ax(3)];
%if verLessThan('matlab', 'R2016b')
%	set(gca, 'XTick', [floor(min(Time)):1:floor(max(Time))])
%else
%	xticks([floor(min(Time)):1:floor(max(Time))])
%end
%title('c) Mean Intensity');
%ylabel('Log Mean Intensity \mu [Rayleighs]');
%xlabel('UT Hour')
%for list_ind = 1:3%numel(timelist)
%    h = plot(xboxlim{list_ind}, yboxlim, 'k');
%    set(h, 'LineWidth', 4)
%    texth = text(xboxlim{list_ind}(2)-2, yboxlim(1)+20, ['Interval ' num2str(list_ind)]);
%    set(texth, 'Color','k', 'FontWeight', 'Bold', 'FontSize', 16)
%end

subplot(3, 1, [3]);
%subplot(4, 1, 4);
h = plot(Time, [cv_557FFC], ...; 0.51*ones(size(cv_557FFC))], 
'HandleVisibility','off');
%legend(h, 'Coefficient of variation', 'Cloud Threshold', 'Location','NorthWest');
hold on;
if verLessThan('matlab', 'R2016b')
	set(gca, 'XTick', [floor(min(Time)):1:floor(max(Time))])
else
	xticks([floor(min(Time)):1:floor(max(Time))])
end
axis tight
ax = axis;
yboxlim = [ax(3) ax(3) ax(4) ax(4) ax(3)];
%plot([Time(1) Time(end)], [0.51 0.51], 'g-', 'DisplayName', 'Cloud Threshold');
title('c) Coefficient of Variation versus Time');
ylabel('Coefficient of Variation');
xlabel('UT Hour')
for list_ind = 1:3%numel(timelist)
    h = plot(xboxlim{list_ind}, yboxlim, 'k');
    set(h, 'LineWidth', 4)
    texth = text(xboxlim{list_ind}(2)-1.75, yboxlim(1)+0.1, ['Interval ' num2str(list_ind)]);
    set(texth, 'Color','k', 'FontWeight', 'Bold', 'FontSize', 16)
end




