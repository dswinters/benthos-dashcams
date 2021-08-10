% Separate the bottom segment of a dive given a timeseries of pressure
% General method for all data versions
function [btime, bdepth] = find_bottom_segment(time, depth)

btime = nan;
bdepth = nan;
% bnum = nan;

vmax = 0.4;
amax = 0.5;
dmin = 2;

dt = gradient(time)*86400;
spd = abs(gradient(depth)./dt);
acc = abs(gradient(spd)./dt);

% Find segments within thresholds
mask = spd < vmax & acc < amax & depth >= dmin;
btms = bwlabel(mask);

% Return longest bottom segment
if any(btms>0)
    bdurs = splitapply(@range, time(btms>0), btms(btms>0));
    [~,idx] = max(bdurs);
    btime = time(btms==idx);
    bdepth = depth(btms==idx);
    % bnum = btms(btms==idx);
end
