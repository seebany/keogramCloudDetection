% function [TimeList, TimeSeconds, Zenith, Azimuth, SavedFileNames] = PFSunDipCalc(FileNames, run_SunDipCalc, location)
% Created and run on Windows with Matlab R2019a.
% Tested on Linux Ubuntu with Matlab R2015b.
%
% Created by David Stuart 2020
% Modified by Alex English 2022
% Documented and maintained by Seebany Datta-Barua
% Illinois Institute of Technology
% 25 Oct 2022
% License GNU GPL v3.
function [TimeList, TimeSeconds, Zenith, Azimuth, SavedFileNames] = PFSunDipCalc(FileNames, run_SunDipCalc, location)
flag = run_SunDipCalc;
switch flag
    case 0
% check saved SunAngles matches current ones
SavedFileStruct = load('SunAngles.mat','DataFileNames');
SavedFileNames = SavedFileStruct.DataFileNames;
if (isequal(SavedFileNames, FileNames))
    load('SunAngles.mat');
    disp('Loaded saved sun dip angles in SunAngles.mat')
else
    error('ERROR - saved dates in SunAngles.mat do not match workspace')
end

save('SunAngles.mat','TimeList','TimeSeconds','Azimuth','Zenith','DataFileNames')

    case 1
%% comment in this section to regenerate sun dip angles (takes ~20min)
%location.longitude = -147.45; %negative = W
%location.latitude = 65.12; %positive = N
%location.altitude = 497; %meters

for i=1:length(FileNames)
%    disp(FileNames{i});
    Time{i} = ncread(FileNames{i},'Time'); % appears to be seconds of UT day
    TimeMin = 1;
    TimeMax = length(Time{i});
    CountNum = TimeMax - TimeMin + 1;
    %     find date from filename
    TempDateStr = FileNames{i};
    TempDateStr = strtok(TempDateStr,'.'); %part before .NC
    TempDateStr = strtok(flip(TempDateStr),'_'); %reverses, so reads after last_
    TempDateStr = flip(TempDateStr); %flips back
    timevec = datevec(TempDateStr,'yyyymmdd');    
    Date = datetime(timevec);%datevec(TempDateStr,'yyyymmdd'));
    TimeSeconds{i} = double(Time{i}(TimeMin:TimeMax)); %might not nead this line
    TimeList{i} = repmat(Date,CountNum,1) + seconds(Time{i}(TimeMin:TimeMax)); %add/catenate date+sec
    [time.year, time.month, time.day, time.hour, time.min, time.sec] = datevec(datenum([repmat(timevec(1:3),CountNum,1), ...
	zeros(CountNum,2), TimeSeconds{i}]));
	time.UTC = zeros(CountNum,1);
    Zenith{i} = zeros(1,TimeMax); %preallocate
    Azimuth{i} = zeros(1,TimeMax);

    tempPosition = sun_position_sdb(time, location);
    Zenith{i} = tempPosition.zenith';
    Azimuth{i} = tempPosition.azimuth';
%    for j=1:TimeMax
%        tempPosition = sun_position_sdb(datestr(TimeList{i}(j)), location);
%        Zenith{i}(j) = tempPosition.zenith;
%        Azimuth{i}(j) = tempPosition.azimuth;
%    end
end
DataFileNames = FileNames;
SavedFileNames = DataFileNames;
save('SunAngles.mat','TimeList','TimeSeconds','Azimuth','Zenith','DataFileNames');%, '-append');
end
end
