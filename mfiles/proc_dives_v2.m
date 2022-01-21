% Use .mat files created by proc_bursts_v2.m to produce
% 1) bottom_segments.mat: a collection of dive bottom segments
% 2) dives.csv: a .csv with dive lat,lon, max depth (1 point per dive)

clear all, close all
% Init dive statistics
ID = [];
TIME = [];
DEPTH = [];
DURATION = [];
TIME_PRE = [];
LAT_PRE = [];
LON_PRE = [];
TIME_POST = [];
LAT_POST = [];
LON_POST = [];
LAT_INTERP = [];
LON_INTERP = [];
BOTTOM_START = [];
BOTTOM_DUR = [];
DISCARD = [];

% Init bottom segments
BOTTOM_TIME = {};
BOTTOM_DEPTH = {};
BOTTOM_NUM = {};

dir_in = '../data/processed/ornitela_bursts';
files = dir(fullfile(dir_in,'*.mat'));

IGNORED = zeros(size(files));

for i = 1:length(files)
    % Load file, check for dive data structure(s)
    f_in = fullfile(files(i).folder,files(i).name);
    m = matfile(f_in);
    varlist = who(m);
    didx = find(contains(varlist,'d')); % dive structures
    load(f_in,'gps');

    % Count dives
    for ii = 1:length(didx)

        dtype = varlist{didx(ii)};
        fprintf('\rProcessing %s [%d of %d] - %s',files(i).name,i,length(files),dtype);
        tmp = load(f_in,dtype);
        dives = tmp.(dtype); clear tmp

        % Initialize dives stats

        % bottom_start = nan(nd,1);
        % bottom_dur = nan(nd,1);
        % discard = false(nd,1);

        % Populate dive stats
        td = splitapply(@maxidx, [dives.dn, dives.depth], dives.num);
        [time, depth] = deal(td(:,1), td(:,2)); % Maximum depth & corresponding time
        duration = splitapply(@range, dives.dn, dives.num)*86400;

        dt = gps.dn - time'; dt(dt>=0)=nan;
        [~,ipre] = max(dt); % index of nearest prior GPS
        dt = gps.dn - time'; dt(dt<=0)=nan;
        [~,ipost] = min(dt); % index of nearest posterior GPS

        time_pre = gps.dn(ipre);   % \
        time_post = gps.dn(ipost); % |
        lat_pre = gps.lat(ipre);   % |  prior/posterior time & location
        lat_post = gps.lat(ipost); % |
        lon_pre = gps.lon(ipre);   % |
        lon_post = gps.lon(ipost); % /

        [~,iu] = unique(gps.dn);
        lat_interp = interp1(gps.dn(iu),gps.lat(iu),time); % \
        lon_interp = interp1(gps.dn(iu),gps.lon(iu),time); % / interpolated location

        % Append dive stats
        nd = max(dives.num);
        id = str2num(extractBefore(files(i).name,'_'));
        ID           = cat(1, ID,           id*ones(nd,1));
        TIME         = cat(1, TIME,         time);
        DEPTH        = cat(1, DEPTH,        depth);
        DURATION     = cat(1, DURATION,     duration);
        TIME_PRE     = cat(1, TIME_PRE,     time_pre);
        LAT_PRE      = cat(1, LAT_PRE,      lat_pre);
        LON_PRE      = cat(1, LON_PRE,      lon_pre);
        TIME_POST    = cat(1, TIME_POST,    time_post);
        LAT_POST     = cat(1, LAT_POST,     lat_post);
        LON_POST     = cat(1, LON_POST,     lon_post);
        LAT_INTERP   = cat(1, LAT_INTERP,   lat_interp);
        LON_INTERP   = cat(1, LON_INTERP,   lon_interp);

        bottom_time = cell(nd,1);
        bottom_depth = cell(nd,1);

        % fprintf('\n')
        for d = 1:nd
            % fprintf('\r  Finding bottom segments [dive %d of %d]',d,nd);
            [bottom_time{d}, bottom_depth{d}] = ...
                find_bottom_segment(dives.dn(dives.num==d), dives.depth(dives.num==d));
        end
        % fprintf('\n')

        BOTTOM_START = cat(1,BOTTOM_START, cellfun(@min, bottom_time));
        BOTTOM_DUR   = cat(1,BOTTOM_DUR,   cellfun(@(x) range(x)*86400, bottom_time));
        BOTTOM_TIME  = cat(1,BOTTOM_TIME,  bottom_time);
        BOTTOM_DEPTH = cat(1,BOTTOM_DEPTH, bottom_depth);

    end % loop over dive burst types
end % loop over files
fprintf('\n')

% Filter some dives here if necessary
rm = false(size(LAT_PRE));
rm = rm | ~is_in_deployment(TIME,ID);

[utm_x_prev, utm_y_prev, utm_zone_prev] = ll2utm(LAT_PRE(~rm),LON_PRE(~rm));
[utm_x_post, utm_y_post, utm_zone_post] = ll2utm(LAT_POST(~rm),LON_POST(~rm));

dives = table(ID(~rm), datetime(TIME(~rm),'convertfrom','datenum'), DEPTH(~rm), ...
              BOTTOM_DUR(~rm),...
              LAT_INTERP(~rm), LON_INTERP(~rm),...
              datetime(TIME_PRE(~rm),'convertfrom','datenum'), LAT_PRE(~rm), LON_PRE(~rm), ...
              datetime(TIME_POST(~rm),'convertfrom','datenum'), LAT_POST(~rm), LON_POST(~rm), ...
              utm_x_prev, utm_y_prev, utm_zone_prev,...
              utm_x_post, utm_y_post, utm_zone_post,...
              'VariableNames',...
              {'tag','time','depth','bottom_dur'...
               'gps_lat_interp','gps_lon_interp',...
               'gps_time_prev','gps_lat_prev','gps_lon_prev',...
               'gps_time_post','gps_lat_post','gps_lon_post',...
               'utm_x_prev','utm_y_prev','utm_zone_prev',...
               'utm_x_post','utm_y_post','utm_zone_post' ...
              });

[~,sidx] = sort(dives.time);
dives = dives(sidx,:);

writetable(dives,'../data/processed/dives.csv');
disp('Wrote ../data/processed/dives.csv')

bottom = struct();
bottom.time = BOTTOM_TIME;
bottom.depth = BOTTOM_DEPTH;
bottom.time_maxdepth = TIME;
bottom.maxdepth = DEPTH;
bottom.id = ID;
bottom.time_pre = TIME_PRE;
bottom.lat_pre = LAT_PRE;
bottom.lon_pre = LON_PRE;
bottom.time_post = TIME_POST;
bottom.lat_post = LAT_POST;
bottom.lon_post = LON_POST;

% Pre-filter
conds = bottom.time_pre < bottom.time_post; % need ascending and unique times to interp pos
fprintf('"time_post > time_pre" removed %d dives (%.3f%%)\n',sum(~conds),100*(1-mean(conds)));
flds = fields(bottom);
for i = 1:length(flds)
    bottom.(flds{i}) = bottom.(flds{i})(conds);
end

% Interpolate dive locations
disp('Interpolating dive bottom locations')
[bottom.x_pre, bottom.y_pre] = ltln2xy_dashcams(bottom.lat_pre, bottom.lon_pre);
[bottom.x_post, bottom.y_post] = ltln2xy_dashcams(bottom.lat_post, bottom.lon_post);
interp_pos =@(x1,x2,t1,t2,t) ...
    cellfun(@(x1,x2,t1,t2,t) interp1([t1 t2],[x1 x2],t),...
            num2cell(x1), num2cell(x2), num2cell(t1), num2cell(t2), t,...
            'uni', false);
bottom.x = interp_pos(bottom.x_pre, bottom.x_post,...
                      bottom.time_pre, bottom.time_post, bottom.time);
bottom.y = interp_pos(bottom.y_pre, bottom.y_post,...
                      bottom.time_pre, bottom.time_post, bottom.time);

% Compute duration of dives
bottom.dur = cellfun(@(x) range(x)*86400,bottom.time);

% Compute time since/until prev/next GPS fix
tmp = cellfun(@(x) x(1), bottom.time);
bottom.age_pre = (tmp - bottom.time_pre)*86400;
tmp = cellfun(@(x) x(end), bottom.time);
bottom.age_post = (bottom.time_post - tmp)*86400;

save('../data/processed/bottom_segments.mat','-struct','bottom');
disp('Wrote ../data/processed/bottom_segments.mat')
