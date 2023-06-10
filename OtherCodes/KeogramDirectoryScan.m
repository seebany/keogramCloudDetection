% function [FileNames]= KeogramDirectoryScan(DirNames, data_dir, root_dir)
% scans inputed directories and returns list of files in each
% for comparing years worth of keograms
% options for checking completeness of files found without reading files
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
function [FileNames]= KeogramDirectoryScan(DirNames, data_dir, root_dir)

% INPUT DirNames = char vector cell array of folder names, 
% ie DirNames = {'2014'; '2015'}
% OUTPUT FileNames = char vector cell array of all filenames .NC (1D not 2D)
FileNames = [];
wd = cd; 
cd(root_dir);
cd(data_dir);
for i = 1:length(DirNames)
    FileInfo = dir(fullfile(data_dir, DirNames{i},'*.NC'));
    FileName = strcat([data_dir, DirNames{i}, filesep], {FileInfo.name});
    FileNames = [FileNames FileName];
end
cd(wd)
end
