%% ltln2xy_dashcams.m
% Usage: [x y] = ltln2xy_dashcams(lt,ln)
% Description: Convert (lat,lon) to (x,y) coordinates in meters.
% Inputs: lt, ln - matrices of lat/lon data
% Outputs: x, y - matrices of (x,y) coordinates. These will have
%                 the same shape as the input lat/lon data.
%
% Author: Dylan Winters
% Created: 2019-09-12


function [x y] = ltln2xy_dashcams(lt,ln)

% Define map reference point for converting to x,y coordinates
% NOTE: This may not be final - this is just a reference that I picked near the
%       Columbia River mouth.
ll0 = [46.254271, -124.039778]; % reference position
psi0 = 0; % reference angle
h0 = 0; % reference height

sz = size(lt);
lla = [lt(:), ln(:), 0*ln(:)]; % lat,lon,alt
xyz = lla2flat(lla, ll0, psi0, h0);
x = reshape(xyz(:,2),sz);
y = reshape(xyz(:,1),sz);
