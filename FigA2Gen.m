% function [] = FigA2Gen(data_dir)
% generates English et al., paper Fig A2
% which contains a subplot of 1)a calibrated but not
% flat-field corrected (FFC) keogram of 01/01/2014;
% 2) the coefficient of variation of the pre-FFC keogram;
% 3) the flat-field gain for each year of 2014-2017 vs elevation;
% 4) the FFC keogram for 01/01/2014;
% 5) the coefficient of variation before and after FFC.
%
% The files CloudData_01-Jan-2014.mat and CloudShapeYearly.mat
% must exist in the Data/ folder.

function [] = FigA2Gen(data_dir)

% Load Keogram for 01/01/2014.
%disp('Loading KeogCloudData.mat')
%load([data_dir filesep 'KeogCloudData.mat'])
keog_filename = 'KeogData_01-Jan-2014.mat';
disp(['Loading ' keog_filename])
load([data_dir filesep keog_filename])
disp('Loaded')

% Load flat-field gain curves for 2014-2017.
ffg_filename = 'CloudShapeYearly.mat';
% The file CloudShapeYearly.mat is generated in steps P0-P3, so gets
% stored in the working folder at the time of the run.
try
	disp(['Loading ' ffg_filename]);
	load([data_dir filesep ffg_filename]) 
catch
	load(ffg_filename)
	disp('Loaded')
end

% Select the keograms for 557.7 nm (column 4) before and after flat-field
% correction.
preFFCKeog_557 = squeeze(CalInt(:,4,:));
KeogFFC_557 = squeeze(FFC(:,4,:));

% Convert the seconds of day into decimal hour.
Time = rem(datenum(TimeList),1)*24;

% Extract the coefficient of variation before and after FFC.
cv_557FFC = cv_FFC(4, :);
cv_557preFFC = cv_cal(4,:);

%---------Plot the cropped keogram scaled to Rayleighs but before
%---------flat-field correction.
f1 = figure; figure(f1);
subplot(3, 2, 1);

theta = [10:170]; %10:10:170
% Fig a) plot the pre-flat-field-correction keogram.
imagesc(Time, theta, squeeze(preFFCKeog_557));
if verLessThan('matlab', 'R2016b')
	set(gca, 'XTick', [floor(min(Time)):1:floor(max(Time))])
else
	xticks([floor(min(Time)):1:floor(max(Time))])
end
hold on;
%ax = axis;
xlabel('UT Hour')

title(['a) Pre-FFC 557.7 nm Keogram ' datestr(TargetDate, 'mmm dd, yyyy')])%Jan 1 2014');
ylabel('Elevation Angle \newline along the meridian \newline [\theta from N]');
a = colorbar;
ylabel(a, 'Intensity [Rayleighs]');
clims = caxis;
caxis([0 clims(2)*.50]);

%-----Plot the pre-FFC coefficient of variation vs time.
subplot(3,2,3);
plot(Time, cv_557preFFC);
hold on
uniformlyLit_thresh = 0.15;
plot([Time(1), Time(end)], uniformlyLit_thresh*ones(1,2), 'k--')
ind_uniformlyLit = find(cv_557preFFC <= 0.15);
scatter(Time(ind_uniformlyLit), 0.8*ones(1,numel(ind_uniformlyLit)), 3,'filled');
axis tight
ax = axis; 
axis([ax(1:2), 0, 1.25])
a = colorbar;
set(a,'visible','off')

if verLessThan('matlab', 'R2016b')
	set(gca, 'XTick', [floor(min(Time)):1:floor(max(Time))])
else
	xticks([floor(min(Time)):1:floor(max(Time))])
end
legend('Pre-FFC \it{c}', ['\it{c} = ' num2str(uniformlyLit_thresh)], ...
	['\it{c} <= ' num2str(uniformlyLit_thresh)], ...
	'Location', 'Best');%'EastOutside');
title(['b) Pre-FFC 557.7 nm Coefficient of Variation']);% ' datestr(TargetDate, 'mmm dd, yyyy')])%Jan 1 2014');
%-----Plot the flat-field gains vs elevation for 2014-2017 annually.
subplot(3,2,[5 6]);
for ind_year = 1:4
	ffg(:,ind_year) = CloudShapeYearly{ind_year}(:,4);
end
plot(theta, ffg);
legend('2014','2015','2016','2017', 'Location', 'Best');
axis tight
ax = axis; 
%axis([ax(1:2), 0, 1.25])
title(['c) 557.7 nm Flat-field Gain 2014-2017']);

%-----Plot the flat-field corrected keogram.
% Fig d) plot the flat-field-corrected keogram.
subplot(3,2,2);

imagesc(Time, theta, squeeze(KeogFFC_557));
if verLessThan('matlab', 'R2016b')
	set(gca, 'XTick', [floor(min(Time)):1:floor(max(Time))])
else
	xticks([floor(min(Time)):1:floor(max(Time))])
end
hold on;
%ax = axis;
xlabel('UT Hour')

title(['d) Flat-field-corrected 557.7 nm Keogram ' datestr(TargetDate, 'mmm dd, yyyy')])%Jan 1 2014');
ylabel('Elevation Angle \newline along the meridian \newline [\theta from N]');
a = colorbar;
ylabel(a, 'Intensity [Rayleighs]');
clims = caxis;
caxis([0 clims(2)*.50]);

%---------Plot the pre- and post-FFC coefficients of variation.
subplot(3,2,4);
plot(Time, [cv_557preFFC', cv_557FFC']);
hold on
axis tight
ax = axis; 
axis([ax(1:2), 0, 1.25])
if verLessThan('matlab', 'R2016b')
	set(gca, 'XTick', [floor(min(Time)):1:floor(max(Time))])
else
	xticks([floor(min(Time)):1:floor(max(Time))])
end
legend('Pre-FFC \it{c}', 'Post-FFC \it{c}', ...
	'Location', 'Best');%'EastOutside');
a = colorbar;
set(a,'visible','off')
title(['e) Pre-FFC and Post-FFC 557.7 nm Coefficient of Variation']);% ' datestr(TargetDate, 'mmm dd, yyyy')])%Jan 1 2014');
