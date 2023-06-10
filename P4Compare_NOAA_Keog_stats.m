% function [ideal_thresh, darksky_cutoff, numbers_for_thresh, percent_for_thresh] = P4Compare_NOAA_Keog_stats(data_dir, satlist, target_year, testcolor, COV)
% loads NOAA_Keog.mat to compute mislabeling rates based on the cloud masks
% and corresponding coefficient of variation.
% Want to find what percent of cloud free are correctly identified and
% incorrectly and percent cloudy correctly and incorrectly identified
%
% Inputs:
%	data_dir: string path to the folder containing NOAA_Keog_Data.mat
%	satlist:
%	target_year:
% 	testcolor: string for keogram color to use 'red', 'green'
%	COV: a user-specified threshold, if the user doesn't want the full search.
%	dist_rank: an integer 1:9 indicating if the closest pixel to Poker Flat should be used (1) or one of the 8 pixels surrounding that pixel, in order of increasing distance.
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
% 17 May 2023: Seebany Datta-Barua: Adding an option to filter the comparison data to compute statistics for a particular NOAA pixel, as a sensitivity study. 
% Variable dist_rank is an integer 1:9 with 1 indicating the closest pixel, and 9 the furthest of the 9 pixels saved.

function [ideal_thresh, darksky_cutoff, numbers_for_thresh, percent_for_thresh]...
	 = P4Compare_NOAA_Keog_stats(data_dir, satlist, target_year, testcolor,...
	 titleprefix, dist_rank, NOAA_cloudy_mask, NOAA_clear_mask, ...
	darksky_cutoff, COV)

% Set std_flag to 'std' if you want to use the standard deviation of the 557.7 nm
% emission instead of coefficient of variation as the detection metric.
std_flag = ''; %Other option is 'std'

% Load the previously-created list of NOAA/Keogram conjunctions.
%fullNOAA_Keog_Data = 
load([data_dir filesep 'NOAA_Keog_Data.mat']);

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

% Make string arrays of the year names.
target_year_string_comp = '';
target_year_string_titles = '';
for i = 1:length(target_year)
    target_year_string_comp =[target_year_string_comp num2str(target_year(i))];
    target_year_string_titles =[target_year_string_titles ' ' num2str(target_year(i))];
end

% Clear out any old output files to prepare to write a new one.
% CloudCompareStats doesn't appear to get written as an output file.
StatsExcelFileName = ['CloudCompareStats' target_year_string_comp '.xlsx'];
if exist(StatsExcelFileName)
    delete(StatsExcelFileName);
end
% Clear the output file if it exists.
filename = ['StatsNumbers' target_year_string_comp '_' testcolor '.xlsx'];
if exist(filename)
    delete(filename);
end
MatName = ['Stats' target_year_string_comp '_' testcolor '.mat'];

%total_number = {};
%total_percent = {};

% Initialize an array of possible thresholds to test.
if isempty(std_flag)
    thresh_list = 0.01:0.01:1;
else
    % SDB Testing std as metric instead of cv. 11/8/22.
    thresh_557_list = linspace(0,3e3);
end

cloud_cat = [];
timediff = [];
cv_FFC2 = [];
cv_avgint = [];
%% SDB testing just std alone as metric. 11/8/22.
cv_std_557 = [];
 
% Loop through each year to concatenate a list of events.
for i = 1:length(target_year)
            %year{i} = num2str(target_year(i));
            %%year(i) = num2str(target_year(i));
            
	% Loop through each NOAA satellite.
        for s = 1:length(satlist)
                check = 0;
                sat = satlist{s};
                % This doesn't work with R2017b, which is version 9.3.
                if verLessThan('matlab', '9.3.1')%'R2018a')
                    PFNOAA_Keog = NOAA_Keog_Data{find(strcmp(sat_track, sat) + (year_track == target_year(i)) == 2)};
                else
                    PFNOAA_Keog = NOAA_Keog_Data{find((sat_track == sat) + (year_track == target_year(i)) == 2)};
                end
                %                 load(['PFNOAA2_Keog' num2str(target_year(i)) '_' sat '.mat']);
                
                % Construct arrays concatenating all satellites.
                cc_temp = PFNOAA_Keog.cloud_mask;
                if size(cc_temp, 1) ~= 0
                    cloud_cat = [cloud_cat cc_temp'];
                    %     cloud_cat = [cloud_cat cc'];
                    timediff_temp = PFNOAA_Keog.TimeDiff;
                    timediff = [timediff timediff_temp'];
                    %     TimeDiff = [TimeDiff timediff'];
		    if strcmp(testcolor, 'green')
                	    cv_avgint_temp = PFNOAA_Keog.AvgInt_557_FFC;
                	    cv_avgint = [cv_avgint cv_avgint_temp'];
                	    cv_FFC2_temp = PFNOAA_Keog.cv_FFC_557;
                	    cv_FFC2 = [cv_FFC2 cv_FFC2_temp'];
                    
                	    % Here is where we could test std as a metric instead
                	    % by storing that value. SDB 11/8/22.
                	    cv_std_557 = [cv_std_557 PFNOAA_Keog.stdFFC_557'];
                    elseif strcmp(testcolor, 'red')
			    % The dark sky is tested with green even though
			    % the cloud test statistic uses the redline.
                	    cv_avgint_temp = PFNOAA_Keog.AvgInt_557_FFC;
                	    cv_avgint = [cv_avgint cv_avgint_temp'];
                	    cv_FFC2_temp = PFNOAA_Keog.cv_FFC_630;
                	    cv_FFC2 = [cv_FFC2 cv_FFC2_temp'];
		    end % if strcmp(testcolor, 'green')

                    % Here is where we could test std as a metric instead
                    % by storing that value. SDB 11/8/22.
 
                    %             cv_FFC2_4278 = PFNOAA_Keog.cv_FFC_4278;
                    %     cv_FFC_557 = [cv_FFC_557 cv_FFC2_557'];
                    %     cv_FFC_630 = [cv_FFC_630 cv_FFC2_630'];
%                    if s == 1
%                        clear StatsTable
%                        StatsTable = PFNOAA_Keog;
%                    else
%                        StatsTable = [StatsTable; PFNOAA_Keog];
%                    end % if s == 1 (1st satellite iteration)
                end % if size(cc_temp, 1) ~= 0
       	end % for s = 1:length(satlist)
end %for year

cloud_cat = cloud_cat';
% Total number of events at this pixel for which there are data
% from both NOAA and Keogram.
count_total_events = numel(cloud_cat);
timediff = timediff';
darksky_test_statistic = cv_avgint;
test_statistic = cv_FFC2';

% ---------------------------------------------------	    
% Loop through each possible threshold.
for i557 = 1:length(thresh_list)
	thresh = thresh_list(i557);
	% Here we call repeatedly the subfunction.
	[count_Both_CF(i557), count_Both_C(i557), count_NOAACF_KeogC(i557), count_NOAAC_KeogCF(i557), count_total_strong(i557), count_strong_aurora(i557)] = compute_stats_given_threshold(NOAA_clear_mask, NOAA_cloudy_mask, ...
		cloud_cat, thresh, test_statistic, darksky_cutoff, darksky_test_statistic);
end %for i557

% For each threshold, sum the correctly labeled events.            
count_matching = count_Both_CF + count_Both_C;
% Sum the number of mislabeled events.
count_diff = count_NOAAC_KeogCF + count_NOAACF_KeogC;
% Check that they total all the events for which a categorization was possible (i.e., excluding dark sky events).
check = (count_matching + count_diff) == count_strong_aurora;
if any(~check)
	error('Count Matching + Count Diff ~= Count Strong Aurora');
end

% Tabulate percents.
% H0 is cloudy, H1 is clear.
% count_both_CF is true positives.
% count_both_C is true negatives.
% count_NOAAC_KeogCF is false alarm (false positive).
% count_NOAACF_KeogC is missed detection (false negative).
percent_both_CF = (count_Both_CF./count_strong_aurora)*100;
percent_matching = (count_matching./count_strong_aurora)*100;
percent_both_C = (count_Both_C./count_strong_aurora)*100;
percent_NOAAC_KeogCF = (count_NOAAC_KeogCF./count_strong_aurora)*100;
percent_diff = (count_diff./count_strong_aurora)*100;
percent_NOAACF_KeogC = (count_NOAACF_KeogC./count_strong_aurora)*100;

% Compute True skill score (TSS) = 1 - MD - FA = TP/(TP+FN) - FP/(FP+TN)
tss = count_Both_CF/(count_Both_CF + count_NOAACF_KeogC) -...
	count_NOAAC_KeogCF/(count_NOAAC_KeogCF + count_Both_C)

%            
%            NOAA_C_Keog_CF_ind = find(NOAA_C_Keog_CF);% == 3);
%            StatsCat(NOAA_C_Keog_CF_ind) = strcat(StatsCat(NOAA_C_Keog_CF_ind), 'NOAA:C  Keog:CF');
%%            StatsCat(NOAA_C_Keog_CF_ind) = strcat(StatsCat(NOAA_C_Keog_CF_ind), "NOAA: C Keog: CF");
%%            NOAA_C_Keog_CF = NOAA_C_Keog_CF == 3;
%
            % The strlength function was introduced by Mathworks in R2016b according to
            % https://www.mathworks.com/help/matlab/ref/strlength.html
            % Accessed 1 Nov 2022.
%            if verLessThan('matlab', 'R2016b')
%                for j = 1:numel(StatsCat)
%                    StatsCatTest(j) = length(StatsCat{j});
%                end
%            else
%                StatsCatTest = strlength(StatsCat);
%            end
%            % StatsCatTest is an array listing the length of each string
%            % describing the category of each event. Each is only a
%            % 15-character string.
%            if max(StatsCatTest) > 15
%                error('An event is being categorized as more than one stats cat');
%            end

            %             writetable(StatsTable, StatsExcelFileName, 'Sheet', ['PFNOAA_Keog_WStats' num2str(thresh_557) '_' num2str(year(i))]);
%        clear std_FFC_CF std_FFC_C % avggood %NOAA_CF NOAA_C strong 
%        clear NOAA_Keog_CF NOAA_Keog_C NOAA_CF_Keog_C NOAA_C_Keog_CF
%        clear NOAA_CF_Keog_C_ind NOAA_C_Keog_CF_ind
%        if verLessThan('matlab', 'R2016a')
%            year(end) = cellstr('all');
%        else
%            year(end) = 'all';
%        end
        NOAA_Keog_Stats_numbers = table(dist_rank, count_total_events, count_total_strong, count_strong_aurora, count_matching, count_Both_CF, count_Both_C, count_diff, count_NOAAC_KeogCF, count_NOAACF_KeogC);
        NOAA_Keog_Stats_percents = table(dist_rank, count_total_events, count_total_strong, count_strong_aurora, percent_matching, percent_both_CF, percent_both_C, percent_diff, percent_NOAAC_KeogCF, percent_NOAACF_KeogC);
%        sheetname = ['557=' num2str(thresh_557)];
%         if verLessThan('matlab', 'R2016a')
%             xlswrite(filename, NOAA_Keog_Stats_numbers, sheetname);
%             xlswrite(filename, NOAA_Keog_Stats_percents, sheetname, 'Range', 'A7');
%         else
%             writetable(NOAA_Keog_Stats_numbers, filename, 'Sheet', sheetname);
%             writetable(NOAA_Keog_Stats_percents, filename, 'Sheet', sheetname, 'Range', 'A7');
%         end
%        total_number{end+1} = NOAA_Keog_Stats_numbers;
%        total_percent{end+1} = NOAA_Keog_Stats_percents;
        
%        clear count_strong_aurora count_Both_CF count_matching count_Both_C 
%        clear count_NOAAC_KeogCF count_diff count_NOAACF_KeogC count_total_events count_total_strong
%    save(MatName, 'total_number', 'total_percent', 'thresh_557_total_list');

% If a threshold COV has been specified by the user, use that.
% Otherwise, find and use the optimal.
if exist('COV','var')
        ideal_thresh_ind = find(thresh_list == COV);
else
        ideal_thresh_ind = find(percent_diff == min(min(percent_diff)));
end
    
% Pass back the ideal threshold.
ideal_thresh = thresh_list(ideal_thresh_ind(1));
disp(['Numerical best threshold from training data c = ' num2str(ideal_thresh)]);
disp(['with ' num2str(percent_diff(ideal_thresh_ind)) '%']);
disp(['Numerical best threshold from this data set c = ' ...
	num2str(thresh_list(find(percent_diff == min(min(percent_diff)))))]);
disp(['with ' num2str(min(min(percent_diff))) '%']);

plot(thresh_list, percent_diff, 'HandleVisibility', 'off');
hold on
% If there are multiple thresholds that work, choose the first/lowest.
scatter(thresh_list(ideal_thresh_ind(1)), ...
	percent_diff(ideal_thresh_ind(1)), 'filled', ...
	'DisplayName', ['Lowest Mislabeling at Threshold: ' ...
	num2str(thresh_list(ideal_thresh_ind(1))) ' Percent Diff: ' ...
	num2str(percent_diff(ideal_thresh_ind(1))) '%'])
xlabel([upper(testcolor(1)) lower(testcolor(2:end)) ' Threshold']);
ylabel('Percent Mislabeled Events');
title([titleprefix ' Percent mislabeled for NOAA pixel \newline' ...
	num2str(target_dist)  ...
	' km away for' target_year_string_titles]);
grid on
                % Compute the theoretical mislabeling rate.
                x = [0:0.01:1]; % Array of possible test statistic values.
                pdf(1,:) = raylpdf(x,0.15);
                pdf(2,:) = raylpdf(x, 0.5);
                prior(1) = 0.62; % Prior probability of cloudy sky.
                prior(2) = 1 - prior(1); % Prior of clear sky.
                cumdf(1,:) = raylcdf(x,0.15);
                cumdf(2,:) = raylcdf(x,0.5);
                fa = prior(1)*(1 - cumdf(1,:));
                md = prior(2)*cumdf(2,:);
                plot(x, (fa+md)*100);
                disp(['Theoretical mislabeling percent minimum from ' ...
			'pdfs fit to training data, is at c = ' ...
                num2str(x(find(fa+md == min(fa+md))))])
		disp(['which would give ' num2str(percent_diff(find(fa+md == min(fa+md)))) '% mislabeled in this data set.'])
                theotss = 1 - min(fa+md)
                

% Pass back the stats for the threshold given or chosen.
numbers_for_thresh = NOAA_Keog_Stats_numbers;
percent_for_thresh = NOAA_Keog_Stats_percents;

