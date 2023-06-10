% function [] = P5HistogramGen(data_dir, sat_list, year_list,testcolor, COV, avg_int_thresh, titleprefix, dist_rank)
% generates histograms of the coefficient of variation for the two 
% populations of cloudy and clear mask values.
% 
% Created and run on Windows with Matlab R2019a.
% Tested on Linux Ubuntu with Matlab R2015b.
% Requires Statistics and Machine Learning Toolbox
%
% License GNU GPL v3.
% Created by Alex English 2022
% Commented and updated by Seebany Datta-Barua
% 17 Nov 2022
% Illinois Institute of Technology
% 23 May 2023: Seebany Datta-Barua: adding function calls to raylpdf that 
% 	require the Statistics and Machine Learning Toolbox.

function [] = P5HistogramGen(data_dir, sat_list, year_list,testcolor, COV, darksky_thresh, titleprefix, dist_rank, NOAA_cloudy_mask, NOAA_clear_mask)

hist_type = 'probability';
target_year_string_comp = '';
target_year_string_titles = '';
for i = 1:length(year_list)
    target_year_string_comp =[target_year_string_comp num2str(year_list(i))];
    target_year_string_titles =[target_year_string_titles ' ' num2str(year_list(i))];
end

%MatName = ['Stats' target_year_string_comp '_' testcolor '.mat'];

% Load the cloud and keogram event comparison table produced from P3*.m.
load([data_dir filesep 'NOAA_Keog_Data.mat']);
% Load the statistics file produced from P4*.m
%load(MatName);

% Identify the unique distances associated with the nearest pixel and its
% surrounding 8 neighbor pixels.
list = unique(NOAA_Keog_Data{1}.dist);
target_dist = list(dist_rank);

% Select the pixel to compute the statistics for out of each cell array (4 years x 4 NOAA satellites = 16 cell arrays).
for i = 1:numel(NOAA_Keog_Data)

        % Find the (lat,lon) of the nearest pixel by searching for shortest distance.
        distrows = find(NOAA_Keog_Data{i}.dist == target_dist);
        % Filter to keep only those rows.
        temporary{i} = NOAA_Keog_Data{i}(distrows,:);
end
clear NOAA_Keog_Data;

% For the rest of the function, NOAA_Keog_Data only includes information for the one pixel corresponding to the distance rank the user requested via dist_rank.
NOAA_Keog_Data = temporary;
clear temporary list

target_year = year_list; %year_list(y);
% Initialize empty variables.
cloud_cat = [];
TimeDiff = [];
cv_FFC_557 = [];
avg_int = [];
cv_FFC_630 = [];
cv_FFC_428 = [];
% Loop through NOAA satellites.
for k = 1:length(sat_list)
        sat = sat_list{k};
	% Loop through years to be analyzed.
        for i = 1:length(target_year)
                if verLessThan('matlab', '9.3.1')%'R2018a')
                    PFNOAA_Keog = NOAA_Keog_Data{find(strcmp(sat_track, sat) + (year_track == target_year(i)) == 2)};
                else
                    PFNOAA_Keog = NOAA_Keog_Data{find((sat_track == sat) + (year_track == target_year(i)) == 2)};
                end
%            PFNOAA_Keog = NOAA_Keog_Data{find((sat_track == sat) + (year_track == target_year(i)) == 2)};
            cc = PFNOAA_Keog.cloud_mask;
            cloud_cat = [cloud_cat cc'];
            timediff = PFNOAA_Keog.TimeDiff;
            TimeDiff = [TimeDiff timediff'];
            cv_FFC2_557 = PFNOAA_Keog.cv_FFC_557;
            avg_int_temp = PFNOAA_Keog.AvgInt_557_FFC;
            avg_int = [avg_int avg_int_temp'];
            cv_FFC_557 = [cv_FFC_557 cv_FFC2_557'];
        end
end

% Find the events that exceed the dark sky threshold.
avggood = avg_int > darksky_thresh;

disp(['The total number of events is ' num2str(numel(cloud_cat))]);
disp(['The number of events that exceed the dark sky threshold is ' ...
	num2str(sum(avggood))])

% Allow for multiple NOAA masks to be considered as one category.
iscloudy = false(size(cloud_cat));
isclear = false(size(cloud_cat));
for i = 1:numel(NOAA_cloudy_mask)
	iscloudy = iscloudy + cloud_cat == NOAA_cloudy_mask(i);
end
for i = 1:numel(NOAA_clear_mask)
	isclear = isclear + cloud_cat == NOAA_clear_mask(i);
end
cc3_avggood = find(iscloudy & avggood);
cc0_avggood = find(isclear & avggood);

% Print out the counts and statistics.
numH0orH1 = numel(cc3_avggood)+numel(cc0_avggood);
disp(['The number of events that have the clear or the cloudy mask is ' ...
	num2str(numH0orH1)]);
disp(['The number of events that have the cloudy mask is ' num2str(numel(cc3_avggood))])
disp(['The number of events that have the clear mask is ' num2str(numel(cc0_avggood))])
disp(['This means P(H_0) = ' num2str(numel(cc3_avggood)/numH0orH1)]);
disp(['and P(H_1) = ' num2str(numel(cc0_avggood)/numH0orH1)]);
    
% Histogram bar boundaries
edges = 0:0.125:3;
x_limits = [0 2];

    histogram(cv_FFC_557(cc3_avggood), ...
        'Normalization', hist_type, ....
        'DisplayName', ['Cloudy mean = ' num2str(mean(cv_FFC_557(cc3_avggood)))], ...
        'BinEdges', edges); %Strong Cloud
    hold on;
    title([titleprefix ' Normalized histogram ' num2str(target_year) ' ' testcolor 'line']);
    histogram(cv_FFC_557(cc0_avggood), ...
        'Normalization', hist_type, ....
        'DisplayName', ['Clear mean = ' num2str(mean(cv_FFC_557(cc0_avggood)))], ...
        'BinEdges', edges); %Clear
    y_limits = ylim;
    plot([COV COV], [0 max(y_limits)], 'r-', 'DisplayName', ['Coefficient of Variation = ' num2str(COV)])
    ylim(y_limits);
    xlabel('Coefficient of Variation');
    xlim(x_limits)
    switch hist_type
        case 'count'
    ylabel('Frequency');
        case 'probability'
            ylabel('Probability');
    end
    legend(['Cloudy mask = ' num2str(NOAA_cloudy_mask)], ...
	['Clear mask = ' num2str(NOAA_clear_mask)] );
    
                % Also plot Rayleigh distributions.
                % Requires the Statistics & Machine Learning Toolbox
                % Posterior probability of null hypothesis for each x.
                x = [0:0.01:1]; % Array of possible test statistic values.
                pdf(1,:) = raylpdf(x,0.15);
                %pdf(1,:) = chi2pdf(x, 1);
                pdf(2,:) = raylpdf(x, 0.5);
                prior(1) = 0.61; % Prior probability of cloudy sky.
                prior(2) = 1 - prior(1); % Prior of clear sky.
                MAP(1,:) = pdf(1,:).*prior(1); % null = cloudy probability
                MAP(2,:) = pdf(2,:).*prior(2); % alternate = clear
                disp(['Theoretical MAP threshold at c = ' ...
                num2str(x(min(find(diff(MAP)>0))))]) % The theoretical threshold from MAP

                x = [0:0.01:2];
                clear pdf
                pdf(1,:) = raylpdf(x,0.15);
                %pdf(1,:) = chi2pdf(x, 1);
                pdf(2,:) = raylpdf(x, 0.5);
                plot(x, pdf/8); % Scale down by a factor of 8 to line up with the plot better.
                grid on

