% function [NightFileNames, NightCutoffIndex, NightCutoffTimes, NumNightFiles, NightKeogDates] = PruneDuskDawn(DataFileNames, Zenith, SunDipCutoff, TimeList)
% Created and run on Windows with Matlab R2019a.
% Tested on Linux Ubuntu with Matlab R2015b.
%
% Created by David Stuart 2020
% Modified by Alex English 2022
% Documented and maintained by Seebany Datta-Barua
% Illinois Institute of Technology
% 25 Oct 2022
% License GNU GPL v3.
function [NightFileNames, NightCutoffIndex, NightCutoffTimes, NumNightFiles, NightKeogDates] = PruneDuskDawn(DataFileNames, Zenith, SunDipCutoff, TimeList)
j = 0; %counter for non-empty files
NightFileNames = {}; %saves names/dates of keograms withing sundip cutoff
NightCutoffIndex = [];%start/end indices, dimensions (j,2)'
NightKeogDates = NaT;%datetime array of dates (D/M/Y) of keogram night dates
% NightCutoffTimes = datetime;%start/end times UTC, dimensions (j,2)
for i=1:length(DataFileNames)
    SunDip = Zenith{i} - repmat(90,1,length(Zenith{i}));
    NightIndex = find(SunDip > SunDipCutoff); %indices where SunDip > SunDipCutoff,
    %     "night" since not dusk/dawn, tracks for single day
    %     main loop, check if not empty, then error check that all indexs
    %     adjacent
    if (isempty(NightIndex))
        %         all times in entire keogram have sun above cutoff, pop out of loop
        %         expected to happen for some files in late spring/ early fall
        disp(strcat(DataFileNames{i},' entirely above SunDipCutoff, discarded'))
        
    elseif (all(diff(NightIndex)==1))%normal condition, when all 'night' times next to each other
        j = j+1;
        NightFileNames{j} = DataFileNames{i};
        %now save first and last positions as NightCutoffIndex
        NightCutoffIndex(j,:) = [NightIndex(1) NightIndex(end)];
        %         TimeList{1}(1)
        %         TimeList{i}(NightIndex(1))
        %         TimeList{i}(NightIndex(end))
        NightCutoffTimes(j,:) = [TimeList{i}(NightIndex(1)) TimeList{i}(NightIndex(end))];
        NightKeogDates(j) = dateshift(TimeList{i}(NightIndex(1)), 'start', 'day');
    else
        error(strcat('ERROR - SunDipCutoff check file-',DataFileNames{i},'- noncontinuous list of times'))
        %         error, should not occur - all times cutoff should be either start
        %         or end of keogram
    end
end
NumNightFiles = j;
end
