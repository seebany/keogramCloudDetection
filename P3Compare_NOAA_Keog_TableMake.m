% function [] = P3Compare_NOAA_Keog_TableMake(target_year_list, ...
% sat_list, data_dir)
% loads KeogCloudData.mat and NOAACloudData.mat created by P2*.m and 
% P0*.m respectively, to
% create a table NOAA_Keog_Data of NOAA cloud cover index of the same length
% as the coefficient of variation computed from keograms at the
% nearest time and nearest location.
%
% Created and run on Windows with Matlab R2019a.
% Tested on Linux Ubuntu with Matlab R2015b.
%
% License GNU GPL v3.
% Created by Alex English 2022
% Commented and updated by Seebany Datta-Barua
% 17 Nov 2022
% Illinois Institute of Technology
% 16 May 2023 Rearranging loops for 1-to-1 mapping to leverage uniform lat, longs for sensitivity of results to NOAA pixel choice.

function [] = P3Compare_NOAA_Keog_TableMake(target_year_list, sat_list, data_dir, target_lat, target_lon)

tic
load([data_dir filesep 'KeogCloudData.mat']);
load([data_dir filesep 'NOAACloudData.mat']);
NOAA_Keog_Data = {};
count_table = 0;
year_track2 = [];
if ~verLessThan('matlab', 'R2016a')
    sat_track2 = strings();
end

% Loop through each year.
for ind_year = 1:length(target_year_list)
    target_year = target_year_list(ind_year);
    % Loop through each NOAA satellite.
    for ind_sat = 1:length(sat_list)
        sat = sat_list{ind_sat};
        % PFCloudData is a variable stored in NOAACloudData.mat that
        % contains the cloud mask values.
        if verLessThan('matlab', 'R2016a')
            PFCloudDataTable = PFCloudData{find(strcmp(sat_list_track,sat) ...
                + (year_track == target_year) == 2)};
        else
            PFCloudDataTable = PFCloudData{find((sat_list_track == sat) ...
                + (year_track == target_year) == 2)};
%         load(['PFCloudDataTable' num2str(target_year) '_' sat '.mat']);
        end
        % Supposed to be organized like this:
        % PFCloudDataTable = table(year, month, day, time, lat, long, cloud_mask, dist, filename);
%        PFCloudDataTable.Properties.VariableNames(cellstr('year')) = cellstr('year');
%        PFCloudDataTable.Properties.VariableNames(cellstr('month')) = cellstr('month');
%        PFCloudDataTable.Properties.VariableNames(cellstr('day')) = cellstr('day');
%        PFCloudDataTable.Properties.VariableNames(cellstr('time')) = cellstr('time');
%        PFCloudDataTable.Properties.VariableNames(cellstr('lat')) = cellstr('lat');
%        PFCloudDataTable.Properties.VariableNames(cellstr('long')) = cellstr('long');
%        PFCloudDataTable.Properties.VariableNames(cellstr('mask')) = cellstr('cloud_mask');
%        PFCloudDataTable.Properties.VariableNames(cellstr('dist')) = cellstr('dist');
%        PFCloudDataTable.Properties.VariableNames(cellstr('source_file')) = cellstr('filename');

        % Initialize empty fields for the output table.
        year = [];
        month = [];
        dday = [];
        doy = [];
        NOAA_time = [];
        KeogTime = [];
        TimeDiff = [];
        cloud_mask = [];
        cv_FFC_557 = [];
        cv_FFC_630 = [];
        cv_FFC_428 = [];
        dist = [];
        NOAAlat = [];
        NOAAlong = [];
        AvgInt_557_FFC = [];
        stdFFC_557 = [];
        % Initialize an output table with these empty arrays as variable names.
        NOAA_Keog = table(year, month, dday, doy, NOAA_time, KeogTime, TimeDiff, cloud_mask, cv_FFC_557, cv_FFC_630, cv_FFC_428, AvgInt_557_FFC, stdFFC_557, dist,...
            NOAAlat, NOAAlong)
%	% Find the NOAA data rows whose pixels have the desired lat, long.
%	pixelrows = find(PFCloudDataTable.lat == target_lat && ...
%		PFCloudDataTable.long == target_lon);
%
%	% Select just those rows of the table, to loop through.
%	PFCloudDataTable = PFCloudDataTable(pixelrows,:);

        % Loop through each timestamp of that satellite's year's data.
        for i = 1:size(PFCloudDataTable, 1)
            clear day
            clear cv
            % Pick out the date of the NOAA data.
            PFyear = PFCloudDataTable.year(i);
            PFmonth = PFCloudDataTable.month(i);
            PFday = PFCloudDataTable.day(i);
            PFdate = datetime(PFyear, PFmonth, PFday);
            PFdist = PFCloudDataTable.distance(i);
            doy = day(PFdate, 'dayofyear');
	    PFtargettime = PFCloudDataTable.time(i)*3600; % sec of UT day.
            % Find the keogram date for the same day as the NOAA data.
            keog_inddate = find(NDate == PFdate);
            % If there is a keogram for that date,
            if ~isempty(keog_inddate)
                try
		    % Extract the row index corresponding to each wavelength.
                    greenind = find(round(NWavelength(keog_inddate,:)) == 558);
                    redind = find(round(NWavelength(keog_inddate,:)) == 630);
                    blueind = find(round(NWavelength(keog_inddate,:)) == 428);
                    
                    % Select the mean, standard deviation, and coefficient
                    % of variation arrays over wavelength x time for that 
		    % keogram for the whole day.
		    cv_fullday = Ncv_FFC{keog_inddate};
                    avg_fullday = NAvgIntensity{keog_inddate};
                    stdev_fullday = Nstd_FFC{keog_inddate};
                    % Extract just the wavelength-specific array.
		    AvgInt_557_fullday = avg_fullday(greenind,:);
                    std557_fullday = stdev_fullday(greenind,:);
                    cv_428_fullday = cv_fullday(blueind,:);
                    cv_557_fullday = cv_fullday(greenind,:);
                    cv_630_fullday = cv_fullday(redind,:);

                    % Pick the array of keogram timestamps for that night's data.
                    KeogTimeSec = NTimeSeconds{keog_inddate};
                    % Find the keogram time that is closest to the NOAA image
                    % time.
                    diff_time = min(abs(KeogTimeSec - PFtargettime));
	    	    % If the closest time is actually reasonably close, 
		    % as in within 20 sec, proceed.
                    if diff_time < 20 
                    	i
			disp(['Diff Time = ' num2str(diff_time) ' s']);
			% Find the keogram indices that all have the same minimum time.
			ind_time = find(abs(KeogTimeSec - PFtargettime) == diff_time);
%			% Find the distance that is closest at that time.
%			nearestdist = min(PFdist);

%                    	% NOAA_Keog is the output table.  Will be empty at the
%                    	% beginning.  Once populated, the next steps check for
%                    	% whether there is already a comparison entry for that
%                    	% doy, and then also for that keogram timestamp.
%                    	ind_doy = find(NOAA_Keog.doy == doy);
%                    	if ~isempty(ind_doy)
			if isempty(NOAA_Keog)
                            NOAA_Keog.year(1) = PFyear;
			    NOAA_Keog.month(1) = PFmonth;
			    NOAA_Keog.dday(1) = PFday;
                            NOAA_Keog.doy(1) = doy;
                            NOAA_Keog.NOAA_time(1) = PFtargettime; %PFCloudDataTable.time(i)*3600;
                            NOAA_Keog.KeogTime(1) = KeogTimeSec(ind_time);
			    NOAA_Keog.cloud_mask(1) = PFCloudDataTable.mask(i);
                            
			    NOAA_Keog.cv_FFC_557(1) = cv_557_fullday(ind_time);
                            NOAA_Keog.cv_FFC_630(1) = cv_630_fullday(ind_time);
                            NOAA_Keog.cv_FFC_428(1) = cv_428_fullday(ind_time);
                            NOAA_Keog.AvgInt_557_FFC(1) = AvgInt_557_fullday(ind_time);
                            NOAA_Keog.stdFFC_557(1) = std557_fullday(ind_time);
                            NOAA_Keog.TimeDiff(1) = diff_time;
%                        
%                            i
%                            %PFdist = PFCloudDataTable.dist(i);
                            NOAA_Keog.dist(1) = PFdist;
                            NOAA_Keog.NOAAlat(1) = PFCloudDataTable.lat(i);
                            NOAA_Keog.NOAAlong(1) = PFCloudDataTable.long(i);

%                            keog_indtime = find(NOAA_Keog.KeogTime == KeogTimeSec(ind_time));
%                            checkind = keog_indtime;
                        else
%                            checkind = [];
%                    	end
%                    	cv_FFC_557 = cv_557_fullday(ind_time);
%                    	cv_FFC_630 = cv_630_fullday(ind_time);
%                    	cv_FFC_428 = cv_428_fullday(ind_time);
%                    	if isempty(checkind)
                            if verLessThan('matlab', '2016a') & ~isempty(NOAA_Keog)
%                                % Want to create one dummy row at the end of the table. 
                                NOAA_Keog = NOAA_Keog([1:end,end], :);
                            else
                        	NOAA_Keog.KeogTime(end+1) = KeogTimeSec(ind_time);
                            end
                            NOAA_Keog.year(end) = PFyear;
			    NOAA_Keog.month(end) = PFmonth;
			    NOAA_Keog.dday(end) = PFday;
                            NOAA_Keog.doy(end) = doy;
                            NOAA_Keog.NOAA_time(end) = PFtargettime; %PFCloudDataTable.time(i)*3600;
                       	    NOAA_Keog.KeogTime(end) = KeogTimeSec(ind_time);
                            NOAA_Keog.cloud_mask(end) = PFCloudDataTable.mask(i);
                            NOAA_Keog.cv_FFC_557(end) = cv_557_fullday(ind_time);
                            NOAA_Keog.cv_FFC_630(end) = cv_630_fullday(ind_time);
                            NOAA_Keog.cv_FFC_428(end) = cv_428_fullday(ind_time);
                            NOAA_Keog.AvgInt_557_FFC(end) = AvgInt_557_fullday(ind_time);
                            NOAA_Keog.stdFFC_557(end) = std557_fullday(ind_time);
                            NOAA_Keog.TimeDiff(end) = diff_time;
%                        
%                            i
%                            %PFdist = PFCloudDataTable.dist(i);
                            NOAA_Keog.dist(end) = PFdist;
                            NOAA_Keog.NOAAlat(end) = PFCloudDataTable.lat(i);
                            NOAA_Keog.NOAAlong(end) = PFCloudDataTable.long(i);
			end % if isempty(NOAA_Keog)
%                    	else % if isempty(checkind)
%			    % If there is a closer comparison point, replace the
%			    % table data with that closer point's data.
%                            if PFdist < NOAA_Keog.dist(checkind)
%                                NOAA_Keog.dist(checkind) = PFdist;
%                            	NOAA_Keog.cloud_mask(checkind) = PFCloudDataTable.cloud_mask(i);
%                            	NOAA_Keog.cv_FFC_557(checkind) = cv_FFC_557;
%                            	NOAA_Keog.cv_FFC_630(checkind) = cv_FFC_630;
%                            	NOAA_Keog.cv_FFC_428(checkind) = cv_FFC_428;
%                            	NOAA_Keog.TimeDiff(checkind) = diff_time;
%                            	NOAA_Keog.NOAAlat(checkind) = PFCloudDataTable.lat(i);
%                            	NOAA_Keog.AvgInt_557_FFC(checkind) = AvgInt_557_fullday(ind_time);
%                            	NOAA_Keog.stdFFC_557(checkind) = std557_fullday(ind_time);
%                            	NOAA_Keog.NOAAlong(checkind) = PFCloudDataTable.long(i);
%                            	NOAA_Keog.NOAA_time(checkind) = PFCloudDataTable.time(i)*3600;
%                            end % if dist < NOAA_Keog.dist(checkind)
%                    	end % if isempty(checkind)
                    
                    end % if diff_time < 20
                catch
                    disp('pause');
                end
            end % ~isempty(keog_inddate)
        end % for i = 1:size(PFCloudDataTable, 1)
%         PFNOAA_Keog = NOAA_Keog;
%         save(['PFNOAA2_Keog' num2str(target_year) '_' sat '.mat'], 'PFNOAA_Keog');
        count_table = count_table+1;
        NOAA_Keog_Data{count_table} = NOAA_Keog;
        year_track2(count_table) = target_year;
        if verLessThan('matlab', 'R2016a')
            sat_track2(count_table) = cellstr(sat);
        else
            sat_track2(count_table) = sat;
        end
%         writetable(NOAA_Keog, excel_filename, 'Sheet', ['PFNOAA_Keog' num2str(target_year) '_' sat]);
    end % for ind_sat = 1:length(sat_list)
end % for ind_year = 1:length(target_year_list)
% PFNOAA_Keog = NOAA_Keog;
% save(['PFNOAA_Keog' num2str(target_year) '_' sat '.mat'], 'PFNOAA_Keog');
year_track = year_track2;
sat_track = sat_track2;
save([data_dir filesep 'NOAA_Keog_Data.mat'], 'NOAA_Keog_Data', 'year_track', 'sat_track');
%save(['NOAA_Keog_Data_lat' num2str(target_lat), '_lon' num2str(target_lon) '.mat'], 'NOAA_Keog_Data', 'year_track', 'sat_track');
toc
