% function [CalIntensity, AvgIntensity, Wavelength, CloudShapeOut, FFC, std_FFC, AvgIntensityFFC, cv_FFC, NormFFC, Date, TimeList, TimeSeconds, cv_cal]...
%	= KeogramRead(NCFilename, CloudShapeIn, TimeCutoffIndex, CutoffAngle, slash, root_dir, data_dir)
% reads keogram files and produces the flat-field-corrected keograms as outputs.
%
% Created and run on Windows with Matlab R2019a.
% Tested on Linux Ubuntu with Matlab R2015b.
%
% Created by David Stuart 2020
% Modified by Alex English 2022
% Documented and maintained by Seebany Datta-Barua
% Illinois Institute of Technology
% 25 Oct 2022
% License GNU GPL v3.

function [CalIntensity, AvgIntensity, Wavelength, CloudShapeOut, FFC, std_FFC, AvgIntensityFFC, cv_FFC, NormFFC, Date, TimeList, TimeSeconds, cv_cal]...
    = KeogramRead(NCFilename, CloudShapeIn, TimeCutoffIndex, CutoffAngle, slash, root_dir, data_dir)
%either CloudTime or CloudShapeIn must be -1 as flag value
%if TimeCutoff =[] no time cutoff used

disp(strcat(NCFilename,'- ','- TimeCutoff-',num2str(TimeCutoffIndex)));

%read NetCDF file
wd = cd;
cd(root_dir)
cd([data_dir slash NCFilename(end-10:end-7)]);
Time  = ncread(NCFilename,'Time');
PeakIntensity  = ncread(NCFilename,'PeakIntensity');
BaseIntensity  = ncread(NCFilename,'BaseIntensity');
Wavelength  = ncread(NCFilename,'Wavelength');
disp('read, now processing...');
cd(wd);

%     % find date from filename
%     TempDateStr = NCFilename;
%     TempDateStr = strtok(TempDateStr,'.'); %part before .NC
%     TempDateStr = strtok(flip(TempDateStr),'_'); %reverses, so reads after last_
%     TempDateStr = flip(TempDateStr); %flips back
%     Date = datetime(datevec(TempDateStr,'yyyymmdd'));
%     TimeSeconds = double(Time); %might not nead this line
%     TimeList = repmat(Date,length(Time),1) + seconds(Time); %add/catenate date+sec
% find location where background values greater than emission keogram
% Subtract the background keogram.
DiffIntensity = PeakIntensity - BaseIntensity;
% Cutoffs in time for start/end, from element TimeMin through TimeMax
if (isempty(TimeCutoffIndex))
    disp('no TimeCutoff using all times')
    TimeMin = 1;
    TimeMax = length(Time);%ie entire set
else %use presets
    disp('preset TimeCutoff cutting times')
    TimeMin = TimeCutoffIndex(1);
    TimeMax = TimeCutoffIndex(2);
end

% Create a new list of the times of the twilight-removed keograms.
CountNum = TimeMax - TimeMin + 1;
% find date from filename
TempDateStr = NCFilename;
TempDateStr = strtok(TempDateStr,'.'); %part before .NC
TempDateStr = strtok(flip(TempDateStr),'_'); %reverses, so reads after last_
TempDateStr = flip(TempDateStr); %flips back
Date = datetime(datevec(TempDateStr,'yyyymmdd'));
TimeSeconds = double(Time(TimeMin:TimeMax)); %might not nead this line
TimeList = repmat(Date,CountNum,1) + seconds(Time(TimeMin:TimeMax)); %add/catenate date+sec

% Crop elevation angles near the horizon.
AngleLength = 181-2*CutoffAngle; %length of resulting angle dimension
DiffShort = DiffIntensity((CutoffAngle+1):(181-CutoffAngle),:,TimeMin:TimeMax);
CalIntensity = double(DiffShort);
% Rayleighs/Count conversion factor supplied by Don Hampton, placeholder 1s
% for channels where conversion not supplied (freqs auroral light not
% expected) for wavelengths [427.8, 486.1, 520, 557.7, 630.0, 670] nm.
RayleighsPerCount = [25.4, 1, 1, 6.2, 7.8, 1];
RayleighsPerCount = repmat(RayleighsPerCount,AngleLength,1,size(CalIntensity,3)); %now create mat for multiplying with CalIntensity
CalIntensity = CalIntensity .* RayleighsPerCount;
CalIntensity(CalIntensity < 0) = 0; %for sanity remove negative

% Compute the average intensity over all angles, at each wavelength at each time.
AvgIntensity = squeeze(mean(CalIntensity,1));
%xpic = [];
%ypic = [];
%     currently unused
%     [xpic,ypic] = meshgrid(1:(TimeMax-TimeMin+1),(CutoffAngle:(180-CutoffAngle)));

% V = squeeze(std(CalIntensity,0,1));
% CV = V./AvgIntensity;

% Construct 'CloudShape' AngleLengthx6 by averaging times when cloudy
% input times visually identified as cloudy
% average for instant across those times for each channel
% normallizing by avg intensity for each channel for those times
% first normalize by time average (ie Avg Intensity)
NormIntensity = CalIntensity ./ repmat(permute(AvgIntensity,[3 1 2]),AngleLength,1,1);
% load('CloudShape.mat')
%     CloudShapeIn
% CV Norm Intensity
cv_cal = [];
% Compute the sample standard deviation (unbiased).
std_cal = squeeze(std(CalIntensity,0,1));
% AvgIntensitycal appears to be identical to AvgIntensity.
AvgIntensitycal = squeeze(mean(CalIntensity,1));
% Coefficient of variation for calibrated, but not flat-field corrected, keogram.
cv_cal = std_cal ./ AvgIntensitycal; %TEST INDEX
color_row = find(round(Wavelength) == 558);
uniformly_lit_threshold = 0.15;
if (isempty(CloudShapeIn))
    %if null construct cloudshape from within file
%     std_cal = squeeze(std(CalIntensity,0,1));
%     AvgIntensitycal = squeeze(mean(CalIntensity,1));
%     cv_cal = std_cal ./ AvgIntensitycal; %TEST INDEX
    ind4 = find(cv_cal(color_row,:) <= uniformly_lit_threshold);
%     ind5 = find(cv_cal(5,:) <= 0.15);
%     [~,indboth] = ismember(ind4, ind5);
%     indboth(find(indboth == 0)) = [];
    disp('constructing CloudShape')
    CloudTimeIndex = [];
%         CloudTimeIndex(1) = find(TimeSeconds == CloudTime(1));
%         CloudTimeIndex(2) = find(TimeSeconds == CloudTime(2));
%         CloudShape = squeeze(mean(NormIntensity(:,:,CloudTimeIndex(1):CloudTimeIndex(2)) ,3));
%     CloudShape = squeeze(mean(NormIntensity(:,:,ind5(indboth)) ,3));
    CloudShape = squeeze(mean(NormIntensity(:,:,ind4) ,3));
else
    disp('used existing CloudShape')
    CloudShape = CloudShapeIn;
end
CloudShapeOut = CloudShape; %OUTPUT
%     save('CloudShape.mat','CloudShape')
CloudMat = repmat(CloudShape,1,1,size(CalIntensity,3));
% DelNorm = NormIntensity - CloudMat;
% AvgAbsDelNorm = squeeze(mean(abs(DelNorm),1));

% Flat Field Correction Technique (standard technique)
FFC = CalIntensity ./ CloudMat;
std_FFC = squeeze(std(FFC,0,1));
AvgIntensityFFC = squeeze(mean(FFC,1));
cv_FFC = std_FFC ./ AvgIntensityFFC; %TEST INDEX
NormFFC = FFC ./ repmat(permute(AvgIntensityFFC,[3 1 2]),AngleLength,1,1);
% for sanity set = 0 for both when AvgIntensity=0 (rather than inf)
cv_FFC(isnan(cv_FFC)) = 0;
% SDB Commented out on 10/27/22 because I don't have TEMP_Plotting and the if statement
% crashes if NCFilename is an array.
%if NCFilename == 'PKR_SMSP_STD_20140101.NC';
%   TEMP_Plotting
%   disp('pause');
%end
NormFFC(isnan(NormFFC)) = 0;
%     disp('done KeogramRead')
end
