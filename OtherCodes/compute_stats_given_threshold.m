% function [count_Both_CF, count_Both_C, Count_NOAACF_KeogC, Count_NOAAC_KeogCF] = compute_stats_given_threshold(NOAA_clear_mask, NOAA_cloudy_mask, cloud_cat, cloud_thresh, cloud_test_statistic, darksky_thresh, darksky_test_statistic)
% compute mislabeling rates based on the cloud masks
% and corresponding coefficient of variation.
% Want to find what percent of cloud free are correctly identified and
% incorrectly and percent cloudy correctly and incorrectly identified
%
% Inputs:
%	NOAA_clear_mask: 0 or the lower of the two states to be compared, of 0, 1, 2, 3.
%	NOAA_cloudy_mask: 3 or the higher of the two states to be compared, out of 0, 1, 2, 3.
%	cloud_cat: array of all the cloud mask categorizations of all the events to
%		be compared.
%	thresh: keogram threshold value to be used.
%	test_statistic: array of numerical values (i.e., coefficient of variation) of all the events to be compared.
%
% Created and run on Windows with Matlab R2019a.
% Tested on Linux Ubuntu with Matlab R2015b.
%
% License GNU GPL v3.
% Created by Alex English 2022
% Commented and updated by Seebany Datta-Barua
% 17 May 2023
% Illinois Institute of Technology
% Adding an option to filter the comparison data to compute statistics for a particular NOAA pixel, as a sensitivity study.

function [count_Both_CF, count_Both_C, count_NOAACF_KeogC, count_NOAAC_KeogCF, count_total_strong, count_strong_aurora] = compute_stats_given_threshold(NOAA_clear_mask, NOAA_cloudy_mask, cloud_cat, cloud_thresh, cloud_test_statistic, darksky_cutoff, darksky_test_statistic)

%-----------Everything above, i.e., concatenation, should all happen in the 
% calling function.
% If there are disagreements, this is a string that stores the
% reason for the disagreement.
if verLessThan('matlab', 'R2016a')
        DisReason = repmat({''},size(cloud_cat));
else
        DisReason = strings(size(cloud_cat));
end
% Initialize a string for the categorization for each event.
StatsCat = DisReason;

% Filter out the dark sky intervals, which are too dark to
% determine cloud cover.
avggood = darksky_test_statistic > darksky_cutoff;
avggood = avggood';
avgbad_ind = find(avggood == 0);
%if verLessThan('matlab','R2016a')
       % Append a string to all events that have dark sky condition.
       DisReason(avgbad_ind) = strcat(DisReason(avgbad_ind), 'KeogAvgLow');
%else
%       DisReason(avgbad_ind) = strcat(DisReason(avgbad_ind), "KeogAvgLow");
%end
%disp(['Number of non-dark sky events, all possible cloud masks = ' num2str(sum(avggood))])

% Make a true/false array of the true cloud conditions based on NOAA.
NOAA_CF = false(size(cloud_cat));
NOAA_C = false(size(cloud_cat));
for i = 1:numel(NOAA_clear_mask)
    NOAA_CF = NOAA_CF + cloud_cat == NOAA_clear_mask(i);
end
for i = 1:numel(NOAA_clear_mask)
    NOAA_C = NOAA_C + cloud_cat == NOAA_cloudy_mask(i);
end
%keyboard
            % Logical array of events that are definitely clear or
            % definitely cloudy.
            strong = NOAA_CF+NOAA_C;
            weak_ind = find(strong == 0);
            %            if verLessThan('matlab','R2016a')
            DisReason(weak_ind) = cellstr('WeakCloudCat');
            %	    else
            %		DisReason(weak_ind) = "WeakCloudCat";
            %            end
            

            % Create an array of cloud-free true/false using green.
            cv_FFC_557_CF_ind = cloud_test_statistic >= cloud_thresh; % if green is greater than or = 0.25, then instance in cf
            % Create an array of cloudy true/false using green.
            cv_FFC_557_C_ind = cloud_test_statistic < cloud_thresh; % if green < 0.25, cloudy
            %     cv_FFC_CF = cv_FFC_CF_ind;
            
            % For this if case, the decision is based on only the greenline.
            cv_FFC_C_ind = cv_FFC_557_C_ind;
            cv_FFC_C_ind = cv_FFC_C_ind == 1;
            cv_FFC_CF_ind = cv_FFC_557_CF_ind;
            cv_FFC_CF_ind = cv_FFC_CF_ind == 1;
            %     cv_FFC_CF_ind = find(cv_FFC_CF_ind == 1);
            %     cv_FFC_C_ind = find(cv_FFC_C_ind == 1);

            % Making an alternative true/false array based on std only. SDB 11/8/22
%            std_FFC_CF = cv_std_557' >= thresh_557;
%            std_FFC_C = cv_std_557' < thresh_557;
            
            
            % *****************Case 1: truly cloudless, detected cloudless.
            % Sum the logical arrays of cloud-free via metric + truly
            % cloud-free + not dark sky.
%            if isempty(std_flag)
            %NOAA_Keog_CF = cv_FFC_CF_ind + NOAA_CF + avggood;
	    NOAA_Keog_CF = (cv_FFC_CF_ind & NOAA_CF & avggood);
%            else
%            % ***SDB Testing std as metric instead. 11/8/22***
%            NOAA_Keog_CF = (std_FFC_CF & NOAA_CF & avggood);
%            end
            
            % Find where all three conditions are met.
%            NOAA_Keog_CF = NOAA_Keog_CF == 3;
            NOAA_Keog_CF_ind = find(NOAA_Keog_CF);% == 3);
%            StatsCat(NOAA_Keog_CF_ind) = strcat(StatsCat(NOAA_Keog_CF_ind), 'NOAA:CF Keog:CF');
%            StatsCat(NOAA_Keog_CF_ind) = strcat(StatsCat(NOAA_Keog_CF_ind), "NOAA: CF Keog: CF");

            % *******************Case 2: truly cloudy, detected cloudy.
            % Sum the logical arrays of cloudy via metric + truly cloudy +
            % not dark sky.
%            if isempty(std_flag)
            %NOAA_Keog_C = cv_FFC_C_ind + NOAA_C + avggood;
            NOAA_Keog_C = (cv_FFC_C_ind & NOAA_C & avggood);
%            else
%            % ***SDB Testing std as metric instead. 11/8/22***
%            NOAA_Keog_C = (std_FFC_C & NOAA_C & avggood);
%            end
            
            % Find where all three conditions are met.
            NOAA_Keog_C_ind = find(NOAA_Keog_C);% == 3);
            
%            StatsCat(NOAA_Keog_C_ind) = strcat(StatsCat(NOAA_Keog_C_ind), 'NOAA:C  Keog:C ');
%            StatsCat(NOAA_Keog_C_ind) = strcat(StatsCat(NOAA_Keog_C_ind), "NOAA:C Keog:C");

            % Not sure why we need this step. SDB 11/8/22.
%            NOAA_Keog_C = NOAA_Keog_C == 3;
            
            % ***************Case 3: truly cloud-free, detected cloudy.
            % Find cases where metric says cloudy but true state is cloudless.
%            if isempty(std_flag)
            %NOAA_CF_Keog_C = cv_FFC_C_ind + NOAA_CF + avggood;
            NOAA_CF_Keog_C = (cv_FFC_C_ind & NOAA_CF & avggood);
%            else
%            % ***SDB Testing std as metric instead. 11/8/22***
%            NOAA_CF_Keog_C = (std_FFC_C & NOAA_CF & avggood);
%            end

            
            NOAA_CF_Keog_C_ind = find(NOAA_CF_Keog_C);% == 3);
%            StatsCat(NOAA_CF_Keog_C_ind) = strcat(StatsCat(NOAA_CF_Keog_C_ind), 'NOAA:CF Keog:C ');
%            StatsCat(NOAA_CF_Keog_C_ind) = strcat(StatsCat(NOAA_CF_Keog_C_ind), "NOAA: CF Keog: C");
%            NOAA_CF_Keog_C = NOAA_CF_Keog_C == 3;
            
            % ************Case 4: truly cloudy, detected cloud-free.
            % Find cases where metric says cloud-free but true state is
            % cloudy.
%            if isempty(std_flag)
            %NOAA_C_Keog_CF = cv_FFC_CF_ind + NOAA_C + avggood;
            NOAA_C_Keog_CF = (cv_FFC_CF_ind & NOAA_C & avggood);
%            else
%            % ***SDB Testing std as metric instead. 11/8/22***
%            NOAA_C_Keog_CF = (std_FFC_CF & NOAA_C & avggood);
%            end
            
            NOAA_C_Keog_CF_ind = find(NOAA_C_Keog_CF);% == 3);
%            StatsCat(NOAA_C_Keog_CF_ind) = strcat(StatsCat(NOAA_C_Keog_CF_ind), 'NOAA:C  Keog:CF');
%            StatsCat(NOAA_C_Keog_CF_ind) = strcat(StatsCat(NOAA_C_Keog_CF_ind), "NOAA: C Keog: CF");
%            NOAA_C_Keog_CF = NOAA_C_Keog_CF == 3;

            % Count totals by summing logical arrays.
            % count_total_strong for ith year is the number of events that
            % have cloud mask of 0 or 3.
            count_total_strong = sum(strong);%sum(NOAA_C)+sum(NOAA_CF);
            % The last element counts totals over all years.
%            count_total_strong(end) = count_total_strong(end) + count_total_strong(i);
            
            % strong_aurora is a logical array of strong and not-dark.
            strong_aurora = (strong & avggood);
            count_strong_aurora = sum(strong_aurora);% == 2);
%            count_strong_aurora(end) = count_strong_aurora(end)+count_strong_aurora(i);
            
            count_Both_CF = sum(NOAA_Keog_CF);
%            count_Both_CF(end) = count_Both_CF(end)+count_Both_CF(i);
            
            count_Both_C = sum(NOAA_Keog_C);
%            count_Both_C(end) = count_Both_C(end)+ count_Both_C(i);
            
            count_NOAAC_KeogCF = sum(NOAA_C_Keog_CF);
%            count_NOAAC_KeogCF(end) = count_NOAAC_KeogCF(end) + count_NOAAC_KeogCF(i);
            
            count_NOAACF_KeogC = sum(NOAA_CF_Keog_C);
%            count_NOAACF_KeogC(end) = count_NOAACF_KeogC(end) + count_NOAACF_KeogC(i);
            
%            count_total_events = length(cloud_cat);
%            count_total_events(end) = count_total_events(end)+length(cloud_cat);
            
%            count_matching = count_Both_CF + count_Both_C;
%%            count_matching(end) = count_matching(end)+count_matching(i);
%            
%            count_diff = count_NOAAC_KeogCF + count_NOAACF_KeogC;
%            check = (count_matching + count_diff) == count_strong_aurora;
%            if check == 0
%
%                error('Count Matching + Count Diff ~= Count Strong Aurora');
%            end

%            count_diff(end) = count_diff(end)+count_diff(i);
%            StatsTable.DisqualReason = DisReason;
%            StatsTable.StatsCat = StatsCat;
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
            % StatsCatTest is an array listing the length of each string
            % describing the category of each event. Each is only a
            % 15-character string.
%            if max(StatsCatTest) > 15
%                error('An event is being categorized as more than one stats cat');
%            end
            %             writetable(StatsTable, StatsExcelFileName, 'Sheet', ['PFNOAA_Keog_WStats' num2str(thresh_557) '_' num2str(year(i))]);
%        clear std_FFC_CF std_FFC_C % avggood %NOAA_CF NOAA_C strong 
%        clear NOAA_Keog_CF NOAA_Keog_C NOAA_CF_Keog_C NOAA_C_Keog_CF
%        clear NOAA_CF_Keog_C_ind NOAA_C_Keog_CF_ind
%        end %for i = 1:length(target_year)
        
%        percent_both_CF = (count_Both_CF./count_strong_aurora)*100;
%        percent_matching = (count_matching./count_strong_aurora)*100;
%        percent_both_C = (count_Both_C./count_strong_aurora)*100;
%        percent_NOAAC_KeogCF = (count_NOAAC_KeogCF./count_strong_aurora)*100;
%        percent_diff = (count_diff./count_strong_aurora)*100;
%        percent_NOAACF_KeogC = (count_NOAACF_KeogC./count_strong_aurora)*100;
%        if verLessThan('matlab', 'R2016a')
%            year(end) = cellstr('all');
%        else
%            year(end) = 'all';
%        end
%        NOAA_Keog_Stats_numbers = table(year, count_total_events, count_total_strong, count_strong_aurora, count_matching, count_Both_CF, count_Both_C, count_diff, count_NOAAC_KeogCF, count_NOAACF_KeogC);
%        NOAA_Keog_Stats_percents = table(year, count_total_events, count_total_strong, count_strong_aurora, percent_matching, percent_both_CF, percent_both_C, percent_diff, percent_NOAAC_KeogCF, percent_NOAACF_KeogC);
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
%        
%        clear count_strong_aurora count_Both_CF count_matching count_Both_C 
%        clear count_NOAAC_KeogCF count_diff count_NOAACF_KeogC count_total_events count_total_strong
%    end %for i557 = 1:length(thresh_557_list)
%    save(MatName, 'total_number', 'total_percent', 'thresh_557_total_list');
% Detection statistics using greenline only.    


return
%%% Stats iteration analysis
%load([MatName]);
%if strcmp(testcolor, 'red and green')
%    thresh_630_all = cell2mat(thresh_630_total_list);
%    thresh_630 = unique(thresh_630_all);
%    thresh_557_all = cell2mat(thresh_557_total_list);
%    thresh_557 = unique(thresh_557_all);
%    all_diff = zeros(length(thresh_630), length(thresh_557));
%    all_NOAACF_KeogC = all_diff;
%    all_NOAAC_KeogCF = all_diff;
%    for i630 = 1:length(thresh_630)
%        t630 = thresh_630(i630);
%        ind630 = find(thresh_630_all == t630);
%        for i557 = 1:length(thresh_557)
%            t557 = thresh_557(i557);
%            ind = find(thresh_557_all(ind630) == t557);
%            ind = ((i630-1)*length(thresh_557))+ind;
%            ptable = total_percent{ind};
%            all_diff(i630, i557) = ptable.percent_diff(end);
%            all_NOAACF_KeogC(i630, i557) = ptable.percent_NOAACF_KeogC(end);
%            all_NOAAC_KeogCF(i630, i557) = ptable.percent_NOAAC_KeogCF(end);
%        end
%    end
%    
%    f1 = figure; figure(f1);
%    imagesc(thresh_557, thresh_630, all_diff);
%    xlabel('Green Threshold');
%    ylabel('Red Threshold');
%    title('% of the total number of events that disagree');
%    h = colorbar;
%    ylabel(h, '(Number of mislabeled Events / Total Number of Events)*100');
%    saveas(f1, 'PercentMislabeled01.png', 'png');
%    
%    f2 = figure; figure(f2);
%    imagesc(thresh_557, thresh_630, all_NOAACF_KeogC);
%    xlabel('Green Threshold');
%    ylabel('Red Threshold');
%    title('all NOAACF KeogC');
%    saveas(f2, 'AllNOAACFKeogC01.png', 'png');
%    
%    f3 = figure; figure(f3);
%    imagesc(thresh_557, thresh_630, all_NOAAC_KeogCF);
%    xlabel('Green Threshold');
%    ylabel('Red Threshold');
%    title('all NOAAC KeogCF');
%    saveas(f3, 'AllNOAACKeogCF01.png', 'png');
%    
%    [ideal_thresh_630, ideal_thresh_557] = find(all_diff == min(min(all_diff)))
%elseif strcmp(testcolor, 'green')
%    thresh_557_all = cell2mat(thresh_557_total_list);
%    thresh_557 = unique(thresh_557_all);
%    all_diff = zeros(length(thresh_557),1);
%    all_NOAACF_KeogC = all_diff;
%    all_NOAAC_KeogCF = all_diff;
%    for i557 = 1:length(thresh_557)
%        ptable = total_percent{i557};
%        all_diff(i557) = ptable.percent_diff(end);
%        all_NOAACF_KeogC(i557) = ptable.percent_NOAACF_KeogC(end);
%        all_NOAAC_KeogCF(i557) = ptable.percent_NOAAC_KeogCF(end);
%%         all_NOAACF_KeogCF(i557) = ptable.percent_NOAACF_KeogCF(end);
%    end
%    
%    % If a threshold COV has been specified by the user, use that.
%    % Otherwise, find and use the optimal.
%    if exist('COV','var')
%            ideal_thresh_557 =find(thresh_557 == COV);
%    else
%        [ideal_thresh_557] = find(all_diff == min(min(all_diff)));
%    end
%    
%
%%    f1 = figure; figure(f1);
%    plot(thresh_557, all_diff, 'HandleVisibility', 'off');
%    hold on
%    for i = 1:length(ideal_thresh_557)
%        scatter(thresh_557(ideal_thresh_557(i)), all_diff(ideal_thresh_557(i)), 'filled', 'DisplayName', ['557 Threshold: ' num2str(thresh_557(ideal_thresh_557(i))) ' Percent Diff: ' num2str(all_diff(ideal_thresh_557(i))) '%'])
%    end
%    xlabel('Green Threshold');
%    ylabel('Percent Mislabled Events');
%    title(['Percent of events that disagree for' target_year_string_titles]);
%    legend()
%%    saveas(f1, ['PercentMislabeled_' target_year_string_comp '_' testcolor 'std.png'] , 'png');
%    
%    
%%     f2 = figure; figure(f2);
%%     imagesc(thresh_557, thresh_630, all_NOAACF_KeogC);
%%     xlabel('Green Threshold');
%%     ylabel('Red Threshold');
%%     title('all NOAACF KeogC');
%%     saveas(f2, 'AllNOAACFKeogC01.png', 'png');
%%     
%%     f3 = figure; figure(f3);
%%     imagesc(thresh_557, thresh_630, all_NOAAC_KeogCF);
%%     xlabel('Green Threshold');
%%     ylabel('Red Threshold');
%%     title('all NOAAC KeogCF');
%%     saveas(f3, 'AllNOAACKeogCF01.png', 'png');
%    
%    % Pass back the stats for the threshold given or chosen.
%    numbers_for_thresh = total_number{ideal_thresh_557};
%    percent_for_thresh = total_percent{ideal_thresh_557};
%    % Pass back the ideal threshold.
%    ideal_thresh = thresh_557(find(all_diff == min(min(all_diff))))
%    
%    
%elseif strcmp(testcolor, 'red')
%    thresh_630_all = cell2mat(thresh_630_total_list);
%    thresh_630 = unique(thresh_630_all);
%    all_diff = zeros(length(thresh_630),1);
%    all_NOAACF_KeogC = all_diff;
%    all_NOAAC_KeogCF = all_diff;
%    for i630 = 1:length(thresh_630)
%        ptable = total_percent{i630};
%        all_diff(i630) = ptable.percent_diff(end);
%        all_NOAACF_KeogC(i630) = ptable.percent_NOAACF_KeogC(end);
%        all_NOAAC_KeogCF(i630) = ptable.percent_NOAAC_KeogCF(end);
%%         all_NOAACF_KeogCF(i630) = ptable.percent_NOAACF_KeogCF(end);
%    end
%    
%    % If a threshold COV has been specified by the user, use that.
%    % Otherwise, find and use the optimal.
%    if exist('COV','var')
%            ideal_thresh_630 =find(thresh_630 == COV);
%    else
%        [ideal_thresh_630] = find(all_diff == min(min(all_diff)));
%    end
%    
%
%%    f1 = figure; figure(f1);
%    plot(thresh_630, all_diff, 'HandleVisibility', 'off');
%    hold on
%    for i = 1:length(ideal_thresh_630)
%        scatter(thresh_630(ideal_thresh_630(i)), all_diff(ideal_thresh_630(i)), 'filled', 'DisplayName', ['630 Threshold: ' num2str(thresh_630(ideal_thresh_630(i))) ' Percent Diff: ' num2str(all_diff(ideal_thresh_630(i))) '%'])
%    end
%    xlabel('Red Threshold');
%    ylabel('Percent Mislabled Events');
%    title(['Percent of events that disagree for' target_year_string_titles]);
%%    legend()
%%    saveas(f1, ['PercentMislabeled_' target_year_string_comp '_' testcolor std_flag '.png'] , 'png');
%    
%    
%%     f2 = figure; figure(f2);
%%     imagesc(thresh_557, thresh_630, all_NOAACF_KeogC);
%%     xlabel('Green Threshold');
%%     ylabel('Red Threshold');
%%     title('all NOAACF KeogC');
%%     saveas(f2, 'AllNOAACFKeogC01.png', 'png');
%%%     
%%     f3 = figure; figure(f3);
%%     imagesc(thresh_557, thresh_630, all_NOAAC_KeogCF);
%%%     xlabel('Green Threshold');
%%     ylabel('Red Threshold');
%%     title('all NOAAC KeogCF');
%%     saveas(f3, 'AllNOAACKeogCF01.png', 'png');
%%    
 %   % Pass back the stats for the threshold given or chosen.
 %   numbers_for_thresh = total_number{ideal_thresh_630};
 %   percent_for_thresh = total_percent{ideal_thresh_630};
 %%   % Pass back the ideal threshold.
 %   ideal_thresh = thresh_630(find(all_diff == min(min(all_diff))))
%    
%    
%else
%%    disp('ERROR');
%end % if strcmp(testcolor, 'red and green')
