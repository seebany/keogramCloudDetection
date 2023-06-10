% function [] = P1KeogDownload(KeogDownloadFolder, yearfolder);
%Creates List of Keog Files and downloads them.
% ftp://optics.gi.alaska.edu/PKR/DASC/RAW/2014/
% ftp://optics.gi.alaska.edu/PKR/DASC/RAW/2015/
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
function [] = P1KeogDownload(KeogDownloadFolder, yearfolder);

% clear all;close all;clc;
%% read entire directory from Alaska server, takes ~1-2hours to run
% clearvars -except DayDir_save DayDir
tic
%KeogDownloadFolder = '/data2/public/Data/keograms/';%C:\Users\Alex\Desktop\CloudShapeRun\CloudVerificationCode\Data\';
FTPServer = ftp('optics.gi.alaska.edu')%crash here means not connecting to server
rootfolder = 'PKR/DMSP/NCDF';
cd(FTPServer,rootfolder);
%addpath(genpath('C:\Users\Alex\Desktop\CloudShapeRun\Data'));
%yearfolder = ["2014", "2015", "2016", "2017"];
%% yearfolder = ["2018", "2019"];
DayDir = {};

set = 0;
c = 1; %counter for day number
for i=1:length(yearfolder)%loop every year
    if verLessThan('matlab', 'R2016a')
    if ~exist([KeogDownloadFolder yearfolder{i}], 'dir')
        mkdir([KeogDownloadFolder yearfolder{i}]);
    end
    KeogDir = dir([ yearfolder{i}]);
    else
        if ~exist([KeogDownloadFolder num2str(yearfolder(i))], 'dir')
            mkdir([KeogDownloadFolder num2str(yearfolder(i))]);
        end
    KeogDir = dir([ num2str(yearfolder(i))]);
    end
    KeogName = [];
    if length(KeogDir) < 3
        empt = 1;
    else
        empt = 0;
        for k = 3:length(KeogDir)
            n = KeogDir(k).name;
            d = n(end-10:end-3);
            d = str2double(d);
            KeogName(end+1) = d;
        end
    end
    cd(FTPServer,yearfolder(i));%go to year subfolder
    if verLessThan('matlab','R2016a')
        % Workaround for the fact that Matlab R2015b hangs in passive mode
        % and won't list out the directory contents from
        % https://undocumentedmatlab.com/articles/solving-an-mput-ftp-hang-problem
        % accessed 26 Oct 2022.
        sf = struct(FTPServer);
        sf.jobject.enterLocalPassiveMode();        
    end
    YearDir = dir(FTPServer);
    for j=1:length(YearDir)
        try
            n = YearDir(j).name;
            if empt == 0
                d = n(end-10:end-3)
                d = str2double(d);
                x = find(KeogName == d);
                if x == 0
                    mget(FTPServer,YearDir(j).name,[KeogDownloadFolder yearfolder{i}]);
                    j
                end
            else
                mget(FTPServer,YearDir(j).name,[KeogDownloadFolder yearfolder{i}]);
                j
            end
        catch
            disp('pause');
        end
    end
    cd(FTPServer,'..');
end

toc


