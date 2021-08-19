setenv('DASHCAMS','/home/dw/projects/DASHCAMS')

% Don't warn about renaming csv headers using readtable
warning('off','MATLAB:table:ModifiedAndSavedVarnames');

%% Process all sensor bursts
% INPUT:    Raw monthly .csv files
% OUTPUT:   data/processed/ornitela_bursts/*.mat
%           data/processed/ornitela_bursts_summary.txt
% REQUIRES: ornitela_v2_timestamp_correction.m, find_bottom_segment.m, maxidx.m,
%           is_in_deployment.m, ll2utm.m, proc_dive_stats.m
disp('Processing all sensor bursts')
proc_bursts_v2

%% Combine all dive stats into a single .csv file
combine_dive_stats()

%% Combine all GPS locations into a single .csv file
combine_locations()

%% Quit MATLAB
exit
