% This Matlab script is the top level script for detecting clouds using keograms
% collected at Poker Flat Research Range from 2014-2017. Files may be
% temporarily written to your Matlab working directory.
% 
% Created and run on Windows XX with Matlab R2019a.
% Tested on Linux Ubuntu with Matlab R2015b.
% Functions P4_compare_NOAA_Keog_stats.m and P5HistogramGen.m require
% the Statistics and Machine Learning toolbox. 
%
% Created by Alex English 2022
% Documented and maintained by Seebany Datta-Barua
% Illinois Institute of Technology
% 25 Oct 2022
% License GNU GPL v3.

clear
close all

% Change these settings for the user's own configuration.
%root_dir = '/your/path/here/'; 
root_dir = '/data1/home/sdattaba/mfiles/saga/KeogramVerificationCodes/';
KeogDownloadFolder = '/data2/public/Data/keograms/';
output_dir = [root_dir filesep 'Data'];

run_SunDipCalc = 1; %1 = run 0 = already run and saved data, dont run again to save time
CutoffAngle = 10;
SunDipCutoff = 12; % [deg] Angle with respect to the horizon, positive below the horizon, that defines effective nighttime.
% Poker Flat, Alaska, coordinates as listed in the all-sky image fits file headers.
location.latitude = 65.126; 
location.longitude = -147.479; %deg Lat Long location of Poker Flat Alaska research center
location.altitude = 497; % m, this was listed in the sun dip calculation by David Stuart

% Keogram emission to use in parts 4-5.
testcolor = 'green'; %'red and green'
% Dark sky threshold.
darksky_cutoff = 500; % Rayleighs

% test = 'red and green';
% Cloud masks to distinguish between in parts 4-5.
NOAA_cloudy_mask = [2,3];%3;%[2, 3];
NOAA_clear_mask = [0,1];%0;%[0, 1];
% NOAA pixels to try comparing coefficient of variation to, in order of nearness.
dist_list = 1:1; %1:9

% User should select which steps they wish to run (it is possible to skip
% steps that have already been completed, to save time), and create an
% array of the step numbers desired. The possible steps are:
% 0: Download, read, and crop NOAA cloud mask data to the nearest and pixel
% to the ground site, and the 8 surrounding it.
% 1: Download keograms from the Poker Flat Research Range website.
% 2: Calibrate and flat-field correct the keograms.
% 3: Compare the NOAA cloud mask to the keogram coefficient of variation
% and save results in a table.
% 4: Compute correct detection, false alarm, missed detection and correct
% negative rates for the training data; repeat for the testing data.
% 5: Plot histograms for the training and testing years' data.
% 6: Plot Figs 2, 3, 4a, 7 of the paper English et al., (under review). 
% For case 6 to work, cases 0=3 need to have already been run.
% Cases 4-5 together produce Figs 5-6 of the paper. 
run_array = 6;%4:5;%0:5;
% User should not need to change anything below.
%-------------------

% Set up file paths.
DirNames={'2014', '2015', '2016', '2017'};

addpath(genpath(root_dir));

% These appear to be the first keograms of each year to be used.
CloudFileYearly = {'PKR_SMSP_STD_20140101.NC', 'PKR_SMSP_STD_20150111.NC', 'PKR_SMSP_STD_20160101.NC', 'PKR_SMSP_STD_20170101.NC'};
ExcludeFile = 'PKR_SMSP_STD_20151110_old.NC';
Years_Running = 2014:1:2017;
training_years = [2014, 2016];% [2014 2016];
testing_years = [2015,2017];%, 2017]; %[2015 2017];
sat_list = {'NOAA-15', 'NOAA-19', 'METOP-02', 'NOAA-18'};

for i = 1:length(run_array)
    %% Set These Values Before Running
    flag = run_array(i);
    switch flag
        case 0 %Takes ~15 hrs to run
            P0DownloadReadDeleteNOAAData(output_dir, location.latitude, ...
                location.longitude, Years_Running, sat_list); %Downloads NOAA data, reads the data, and saves nearest pixel cloudmask and the 8 surrounding it. ~25 hours to run
        case 1
            P1KeogDownload(KeogDownloadFolder, DirNames); %Downloads all keograms during Years_Running ~1 hr to run
        case 2 %takes ~10 min to run
            P2KeogramCalibrationandFFC(root_dir, KeogDownloadFolder, DirNames, ...
		ExcludeFile, run_SunDipCalc, SunDipCutoff, location, Years_Running, CloudFileYearly, CutoffAngle); %Calibrates and FFC downloaded keograms
        case 3 %Takes less than 10 min to run.  More like 40 s.
            % Loop through NOAA pixels.
            P3Compare_NOAA_Keog_TableMake(Years_Running, sat_list, output_dir, location.latitude, location.longitude); %Organizes NOAA and Keogram data to find points where there is NOAA data and Keogram datawithin 12.5s
        case 4 %Takes less than 10 min to run
            for dist_rank = dist_list
            	f(dist_rank) = figure(dist_rank);
            	subplot(222)
		titleprefix = '(b) ';
	    	[COV(dist_rank), avg_int_thresh, training_number, ...
			training_percent] = P4Compare_NOAA_Keog_stats(...
			output_dir, sat_list, training_years, testcolor, ...
			titleprefix, dist_rank, NOAA_cloudy_mask, NOAA_clear_mask, darksky_cutoff); %uses detection theory on the training data to find the optimal 557nm threshold
            	
		subplot(224)
		titleprefix ='(d) ';
            	[~,~, testing_number, testing_percent] = ...
		P4Compare_NOAA_Keog_stats(output_dir, sat_list, ...
		testing_years, testcolor, titleprefix, dist_rank, ...
		NOAA_cloudy_mask, NOAA_clear_mask, darksky_cutoff, COV(dist_rank)); %uses detection theory on the testing data 


            end

        case 5 %Takes less than a few min to run
            for dist_rank = dist_list
            	f(dist_rank) = figure(dist_rank);
            	subplot(221)
		titleprefix = '(a) ';%['(b) For NOAA cloud mask pixel ' num2str(list(dist_rank)) ' km away \newline'];
            	P5HistogramGen(output_dir, sat_list, training_years, testcolor, COV(dist_rank), darksky_cutoff, titleprefix, dist_rank, NOAA_cloudy_mask, NOAA_clear_mask);
            	
		subplot(223)
		titleprefix = '(c) ';%['(d) For NOAA cloud mask pixel ' num2str(list(dist_rank)) ' km away \newline'];
            	P5HistogramGen(output_dir, sat_list, testing_years, testcolor, COV(dist_rank), darksky_cutoff, titleprefix, dist_rank, NOAA_cloudy_mask, NOAA_clear_mask);
		% EPS will not preserve the transparency of the histogram bars, so
		% print to pdf instead.
		h = gcf;
		set(h, 'PaperOrientation', 'landscape');
		set(h,'PaperUnits','normalized');
		set(h,'PaperPosition', [0 0 1 1]);
		print('-painters','-dpdf',[output_dir filesep ...
			'Percent_mislabeled_Histogram_' testcolor ...
			'_' num2str(NOAA_cloudy_mask) 'iscloudy_' ...
			num2str(NOAA_clear_mask) 'isclear_distance' ...
			num2str(dist_rank) '_2014-17_b0.20.pdf'])
    	    end
	case 6 % Takes a few minutes to run, as loading KeogData.mat takes time.
		% Generate Figure 2 of the paper.
		Fig2Gen(output_dir);
		h = gcf;
		set(h, 'PaperOrientation', 'landscape');
		set(h,'PaperUnits','normalized');
		set(h,'PaperPosition', [0 0 1 1]);
		print('-painters','-dpdf',[output_dir filesep ...
			'Fig2.pdf'])
	 
		% Generate Figure 3 of the paper.
%		Fig3Gen(output_dir);
		h = gcf;
		set(h, 'PaperOrientation', 'landscape');
		set(h,'PaperUnits','normalized');
		set(h,'PaperPosition', [0 0 1 1]);
%		print('-painters','-dpdf',[output_dir filesep ...
%		 	'Fig3.pdf'])

		% Generate Figure 4 of the paper.
%		Fig4Gen();
		h = gcf;
%		saveas(h, [output_dir filesep 'Fig4.eps'], 'epsc')

		% Generate Figure 7 of the paper.
%		Fig7Gen(output_dir);
     		h = gcf;
	        set(h, 'PaperOrientation', 'landscape');
		set(h,'PaperUnits','normalized');
		set(h,'PaperPosition', [0 0 1 1]);
%		print('-painters','-dpdf',[output_dir filesep ...
%		 	'Fig7.pdf'])
    end %switch flag
    
end % for run_array

return
