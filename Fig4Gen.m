% Script Fig4Gen() creates the cloud mask map.
% generates English et al., paper Fig 4(left).
% NOAA data are from
% url = ['https://www.ncei.noaa.gov/data/avhrr-reflectance-cloud-properties-patmos-extended/access/2014/'];
% The file downloaded and plotted is
% file = 'patmosx_v05r03_METOP-02_asc_d20140101_c20160912.nc';
%
% Created and run on Windows with Matlab R2019a.
% Tested on Linux Ubuntu with Matlab R2015b.
%
% Created by Alex English 2022
% Documented and maintained by Seebany Datta-Barua
% Illinois Institute of Technology
% 25 Oct 2022
% License GNU GPL v3.

% Reading PATMOS Data
url = ['https://www.ncei.noaa.gov/data/avhrr-reflectance-cloud-properties-patmos-extended/access/2014/'];
file = 'patmosx_v05r03_METOP-02_asc_d20140101_c20160912.nc';
% Temporarily save the .nc file to the working directory.
websave(file, [url file]);
time = ncread(file, 'time');
scanlinetime = ncread(file, 'scan_line_time');
long = ncread(file, 'longitude');
lat = ncread(file, 'latitude');
cloud_mask = ncread(file, 'cloud_mask');

% Create a 4-shade grayscale color map.
cmap = [0 0 0; 0.33 0.33 0.33; 0.67 0.67 0.67; 1 1 1];
load('mapdata.mat');
% Find data falling within a desired time window, to get a single swath.
% Variable scanlinetime is nlon x nlat, just like cloud_mask is.
% So x1, x2, x3 are logical matrices that are each nlon x nlat.
x1 = scanlinetime > 5.5;%5.89;
x2 = scanlinetime < 6.5;%5.93;
x3 = x1+x2;
% Make a logical array for both criteria being true, that is nlon x nlat.
x = x3 == 2;

swath_mask = cloud_mask;
swath_mask(find(x == 0)) = nan;
scanlinetime2 = scanlinetime.*x;

% Plot a pseudocolor plot.
pcolor(long', lat', swath_mask'); 
colorbar; shading flat; 
colormap(cmap);
hold on
plot(ll_world(:,2),ll_world(:,1),'k','LineWidth', 1.0)
xlim([-180 -135]);
ylim([50 75]);
xlabel('Longitude [deg]')
ylabel('Latitude [deg]')
title(' Jan 01, 2014 05:30-06:30 UT \newline Cloud Mask Data Satellite METOP-02');
cbh = colorbar; %Create Colorbar
cbh.Ticks = [0, 1, 2, 3] ; %Create 8 ticks from zero to 1
row1 = {'Clear' 'Probably' 'Probably' 'Cloudy'};
row2 = {' ' 'Clear' 'Cloudy' ' '};
labelArray = [row1; row2];
tickLabels = strtrim(sprintf('%s\\newline%s\n', labelArray{:}));
cbh.TickLabels = tickLabels;

% Plot location of Poker Flat Research Range.
scatter(-147.47,65.12, 'red', 'filled');

% Create inset figure.
% create smaller axes in top right, and plot on it
ax = axes('Position',[.18 .125 .3 .3]);
pcolor(long', lat', swath_mask');
hold on 
box on
    set(ax, 'XAxisLocation', 'top')
%    set(ax, 'YAxisLocation', 'right')
%    set(gca, 'TickDir', 'out')
xlim([-148 -147]);
ylim([64.5 65.5]);
scatter(-147.47,65.12, 'red');
 
