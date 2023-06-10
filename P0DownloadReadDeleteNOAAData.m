% Downloading NOAA Data from URL, keeping the relevant information, and
% then deleting the file
% ex_url = https://www.ncei.noaa.gov/data/avhrr-reflectance-cloud-properties-patmos-extended/access/2014/patmosx_v05r03_NOAA-19_asc_d20140612_c20160912.nc
% PFCloudDataTable = table(year, month, day, time, lat, long, cloud_mask, dist, filename);
% Created and run on Windows with Matlab R2019a.
% Tested on Linux Ubuntu with Matlab R2015b.
% Functions P4_compare_NOAA_Keog_stats.m and P5HistogramGen.m require
% the Statistics and Machine Learning toolbox. 
%
% Created by Alex English 2022
% Documented and maintained by Seebany Datta-Barua
% Illinois Institute of Technology
% 25 Oct 2022
% License GNU GPL v3.
%
% 1 May 2023
% Seebany Datta-Barua
% Updating method to select nearest pixel and 8 pixels surrounding it. In progress.
function [] = P0DownloadReadDeleteNOAAData(data_dir, PFlat, PFlong, target_year_list, sat_list)
tic
%excel_filename = 'PFNOAACloudData.xlsx'; %Excel file to save the NOAA data to
%delete(excel_filename); 

% NOAA AVHRR netcdf files are located in
% https://www.ncei.noaa.gov/data/avhrr-reflectance-cloud-properties-patmos-extended/access/yyyy/
% where yyyy is four-digit year.
file_beg = 'patmosx_v05r03_';
file_end = '*';
didntwork = {};
PFCloudData = {};
count_tables = 0;
year_track = [];

% Loop through the desired list of years.
for ind_year = 1:length(target_year_list)
    target_year = target_year_list(ind_year);
    parent_url = ['https://www.ncei.noaa.gov/data/avhrr-reflectance-cloud-properties-patmos-extended/access/' num2str(target_year) '/'];
    % Read the list of files in the directory on that website.
	filelist = webread(parent_url);
%    filelist = string(filelist);
    % Loop through the caller-defined list of satellites containing AVHRR.
    for ind_sat = 1:length(sat_list)

	% Initialize a counter of the number of tables.
        count_tables = count_tables+1;
	% Current satellite name string.
        sat = sat_list{ind_sat};

        PFtablefilename = ['PFCloudDataTable' num2str(target_year) '_' sat '.mat']; 
        if exist(PFtablefilename, 'file') %isfile(PFtablefilename)
%            disp('already downloaded');
            load(PFtablefilename);
        else
	    % Search the string list of files from the website for those
	    % that match the satellite name.
            exp = [sat '\w*.nc'];
	    % Create cell array of strings of files associated with that satellie.
            dates1 = regexp(filelist,exp,'match')';
            dates = unique(dates1);
	    % Initialize a table.
            lat = [];
            long = [];
            time = [];%nan*ones(size(dates,1)*9,1);[];
            year = [];%nan*ones(size(dates,1)*9,1);[];
            month = [];%nan*ones(size(dates,1)*9,1);[];
            day = [];%nan*ones(size(dates,1)*9,1);[];
            doy = [];
            cloud_mask = [];
            dist = [];
            satellite = [];
            mask = [];%nan*ones(size(dates,1)*9,1);[];
	    distance = [];%nan*ones(size(dates,1)*9,1);[];
	    filename = [];
	    source_file = [];
%            PFCloudDataTable = table(year, month, day, time, lat, long, cloud_mask, dist, filename);
            %year = target_year;
            for i = 1:size(dates, 1)
                disp([num2str(i) '/' num2str(size(dates,1)) ' of sat ' num2str(ind_sat) '/' num2str(length(sat_list)) ' of year ' num2str(ind_year) '/' num2str(length(target_year_list))]);
                filename = char(dates(i));
		mm = str2double(filename(18:19)); 
		dd = str2double(filename(20:21)); 
                %datechr = date(14:21);
                url = [parent_url];
                filename = [file_beg filename];
                try
		    % Temporarily save the .nc file to the working directory.
                    websave(filename, [url filename]);
		    % Read in the desired variables into Matlab.
                    veclat = ncread(filename, 'latitude'); % 1800x1 array of latitudes in deg.
                    veclong = ncread(filename, 'longitude'); % 3600x1 array of longitudes in deg.
                    cloud_mask = ncread(filename, 'cloud_mask'); %3600x1800 array of integers 0, 1, 2, 3 indicating cloudiness.
                    scanlinetime  =ncread(filename, 'scan_line_time');
		    % Create a grid of lat, lon each 3600 x 1800.
		    gridlat = repmat(veclat', length(veclong), 1); % 3600x1800.
                    gridlong = repmat(veclong, 1, size(gridlat, 2));% 3600x1800
%                     dlat = abs(lat - PFlat);
%                     dlong = abs(long - PFlong);
%                     [row, col] = find(dlat < 10.5 & dlong < 0.0015); % deg
%                     diff = dlat + dlong;
    
                    dist = dist_from_PF(gridlat, gridlong, PFlat, PFlong);
		    % Find the nearest pixel to the lat, lon of PFRR.
                    [nearestrow, nearestcol] = find(dist == min(min(dist)));%< Dist_km_lim);
		    % Keep the cloud mask for the closest pixels and those that
		    % are +/-1 dlat (+/- 0.1 deg) and +/-1 dlon (+/- 0.1 deg).
		    % This assumes the lats and lons are in sequential order.
		    row = nearestrow-1:nearestrow+1;
		    col = nearestcol-1:nearestcol+1;
			ntablerows = numel(scanlinetime(row,col));
		    % Append to existing variables.
%if i == 10 keyboard; end
		    year = [year; repmat(target_year,ntablerows, 1)];
		    month = [month; repmat(mm, ntablerows, 1)];
		    day = [day; repmat(dd, ntablerows, 1)];
		    time = [time; reshape(scanlinetime(row,col),ntablerows,1)];
		    lat = [lat; reshape(gridlat(row,col),ntablerows,1)];
		    long = [long; reshape(gridlong(row,col),ntablerows,1)];
		    mask = [mask; reshape(cloud_mask(row,col),ntablerows,1)];
		    distance = [distance; reshape(dist(row,col),ntablerows,1)];
		    source_file = [source_file; repmat(cellstr(filename),ntablerows,1)];
%                        if ~exist('PFCloudDataTable','var')
		% Populate a table with all cloud mask values for pixels that
		% meet the nearness criteria.
%		for j = 1:length(col)
%                    for k = 1:length(row)
%                            PFCloudDataTable = table(target_year,month,day,... 
%scanlinetime(row(k), col(j)), lat(row(k), col(j)), long(row(k), col(j)), ...
%                            cloud_mask(row(k), col(j)), dist(row(k), col(j)), cellstr(filename));
                %        else
    		%		if verLessThan('matlab','R2016a')
		%		end
%temp = table(year, month, day, time, mask, distance, source_file);%, scanlinetime(row,col), lat(row, col), long(row, col), cloud_mask(row,col), dist(row,col),cellstr(filename));
%                        temp = table(target_year, str2double(datechr(5:6)), str2double(datechr(7:8)), scanlinetime(row(k), col(j)), lat(row(k), col(j)), long(row(k), col(j)), ...
%                            cloud_mask(row(k), col(j)), dist(row(k), col(j)), cellstr(filename));%string(filename));
%                        PFCloudDataTable(end+1:end+ntablerows, :) = temp;
%                        end % if ~exist('PFCloudDataTable', 'var')
%                         PFCloudDataTable.year(end+1) = target_year;
%                         PFCloudDataTable.month(end) = str2double(datechr(5:6));
%                         PFCloudDataTable.day(end) = str2double(datechr(7:8));
%                         PFCloudDataTable.time(end) = scanlinetime(row(k), col(k));
%                         PFCloudDataTable.lat(end) = lat(row(k), col(k));
%                         PFCloudDataTable.long(end) = long(row(k), col(k));
%                         PFCloudDataTable.cloud_mask(end) = cloud_mask(row(k), col(k));
%                         PFCloudDataTable.dist(end) = dist(row(k), col(k));
%                         %                         PFCloudDataTable.satellite(end) = string(sat);
%                         PFCloudDataTable.filename(end) = string(filename);
%                    end % for k = 1:length(row)
%		end % for j = 1:length(col)
		    % If the file reading worked, the .nc file can be deleted.
                    delete(filename);
                catch
                    didntwork{end+1} = [url filename];
                    delete(filename);
                end
            end % for i = 1:size(dates,1)
	    % Store the relevant data in the table.
	    PFCloudDataTable = table(year, month, day, time, lat, long, mask, distance, source_file);%, scanlinetime(row,col), lat(row, col), long(row, col), cloud_mask(row,col), dist(row,col),cellstr(filename));
            try
%                 PFCloudDataTable = table(year, month, day, time, lat, long, cloud_mask, dist, filename);
                PFCloudData{count_tables} = PFCloudDataTable;
                sat_list_track{count_tables} = sat;%(count_tables) = sat;%string(sat);
                year_track(count_tables) = target_year;
		save([data_dir, filesep, 'NOAACloudData.mat'], 'PFCloudData', 'sat_list_track', 'year_track'); %saves data for each year and sat in a table
%                 save(['PFCloudDataTable' num2str(target_year) '_' sat '.mat'], 'PFCloudDataTable'); %saves data for each year and sat in a table
            catch
		keyboard
                error(['Error saving cloud data for year ' num2str(target_year) ' and satellite' sat]);
            end
        end
%         writetable(PFCloudDataTable, excel_filename, 'Sheet', ['PFCloudDataTable' num2str(target_year) '_' sat]);
        clear PFCloudDataTable
%        disp(['finished ' num2str(target_year) ' for sat ' sat]);
    end
%    disp(['finished for all year ' num2str(target_year)]);
end
save([data_dir, filesep, 'NOAACloudData.mat'], 'PFCloudData', 'sat_list_track', 'year_track'); %saves data for each year and sat in a table
toc
%disp('Done Running All');
end

%% functions
% Based on https://www.movable-type.co.uk/scripts/latlong.html
% which uses the haversine function and assumes a spherical Earth.
function [distance_km] = dist_from_PF(lat, long, PFlat, PFlong)
R = 6371E3;
lat1 = PFlat*pi/180; lat2 = lat.*pi/180;
dlat = (PFlat-lat).*pi/180; dlong = (PFlong-long).*pi/180;
a = sin(dlat./2).*sin(dlat./2) + cos(lat1).*cos(lat2).*sin(dlong./2).*sin(dlong./2);
c = atan2(sqrt(a), sqrt(1-a)).*2;
d = c.*R;
% disp([num2str(d) ' meters']);
% disp([num2str(d./1609) ' miles']);
% distance_miles = d./1609;
distance_km = d./1000;
end
