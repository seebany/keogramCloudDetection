% function [] = P2KeogramCalibrationandFFC(root_dir, data_dir, DirNames, ExcludeFile, run_SunDipCalc, SunDipCutoff, location, Years_Running, CloudFileYearly, CutoffAngle);
%Calibrates and flat-field corrects Keograms
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

function [] = P2KeogramCalibrationandFFC(root_dir, data_dir, DirNames, ExcludeFile, run_SunDipCalc, SunDipCutoff, location, Years_Running, CloudFileYearly, CutoffAngle);
tic
%wd = cd; 
%cd(root_dir);
%cd(data_dir);
DirFileNames = KeogramDirectoryScan(DirNames, data_dir, root_dir);
NumDataFiles = 0;
j = 0;

DataFileNames = {};%nonempty filenames
for i=1:length(DirFileNames)
    DirFileNames{i}; %debug
    hasData = NCDataCheck(DirFileNames{i}); %Checks if the data is in that file
    if(hasData & isempty(strfind(DirFileNames{i}, ExcludeFile)))%~strcmp(DirFileNames{i},ExcludeFile))
        NumDataFiles = NumDataFiles + 1;%tick
        j = j+1;%tick
        DataFileNames{j} = DirFileNames{i};%add names of nonempty, changes the ist t ny incude the fies with data
    end
end
NumDirFiles = length(DirFileNames)
NumDataFiles

[TimeList, TimeSeconds, Zenith, Azimuth, SavedFileNames] = PFSunDipCalc(DataFileNames, run_SunDipCalc, location);

[NightFileNames, NightCutoffIndex, NightCutoffTimes, NumNightFiles, NightKeogDates] = PruneDuskDawn(DataFileNames, Zenith, SunDipCutoff, TimeList);
NumNightFiles

%Determines a new calibration every year, if chosen must go through and
%manually choose the cloudy times to analyze
CloudShapeMaster = {};
for i = 1:length(Years_Running)
    Index = strfind(NightFileNames, CloudFileYearly{1});
    Index = find([~isempty(Index)]);%[Index{:}] == 1);
    [ZCalIntensityL, ZAvgIntensity, ZWavelength, ZCloudShapeMaster, ZFFC, Zstd_FFC, ZAvgIntensityFFCZ, Zcv_FFC, ZNormFFC, ZDate, ZTimeList, ZTimeSeconds,ZNcv_cal] = ...
        KeogramRead(CloudFileYearly{i}, [],NightCutoffIndex(Index,:), CutoffAngle, filesep, root_dir, data_dir); %reads the first Kegram file to get some info
    
    %         [ZCalIntensityL, Zxpic, Zypic, ZAvgIntensity, ZWavelength, ZCloudShapeMaster, ZFFC, Zstd_FFC, ZAvgIntensityFFCZ, Zcv_FFC, ZNormFFC, ZDate, ZTimeList, ZTimeSeconds] = ...
    %             KeogramRead(CloudFileYearly{i}, [], CloudTimeSingle,NightCutoffIndex(find(strcmp(NightFileNames, CloudFileYearly{i})),:), CutoffAngle, filesep, root_dir, data_dir); %reads the first Kegram file to get some info
    CloudShapeMaster{i} = ZCloudShapeMaster;
end
save('CloudShapeMasterYearly.mat', 'CloudShapeMaster')
for i=1:length(NightFileNames)
    NightFileNames{i}
    y = NightFileNames{1}(end-10:end-7);
    y = str2num(y);
    [NCalIntensityL{i}, NAvgIntensity{i}, NWavelength(i,:), NCloudShape(i,:,:), NFFC{i}, Nstd_FFC{i}, NAvgIntensityFFC{i}, Ncv_FFC{i}, NNormFFC{i}, NDate(i), NTimeList{i}, NTimeSeconds{i}, Ncv_cal{i}] = ...
        KeogramRead(NightFileNames{i}, CloudShapeMaster{find(Years_Running == y)}, NightCutoffIndex(i,:), CutoffAngle, filesep, root_dir, data_dir);
    clear y
end
%cd(wd);

save([data_dir 'KeogCloudData.mat'], 'NAvgIntensity', 'NDate', 'NTimeList', ...
    'NTimeSeconds', 'Ncv_FFC', 'Nstd_FFC','NWavelength', 'NFFC', '-v7.3');
toc
