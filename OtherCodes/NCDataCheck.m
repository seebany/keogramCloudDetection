% function [hasData] = NCDataCheck(FileName)
% Created and run on Windows with Matlab R2019a.
% Tested on Linux Ubuntu with Matlab R2015b.
%
% Created by David Stuart 2020
% Modified by Alex English 2022
% Documented and maintained by Seebany Datta-Barua
% Illinois Institute of Technology
% 25 Oct 2022
% License GNU GPL v3.
function [hasData] = NCDataCheck(FileName)
%     disp(Filename)
hasData=(length(ncread(FileName,'Time'))~=0);
end
