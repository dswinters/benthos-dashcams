% Use .mat files created by proc_bursts_v2.m to produce
% 1) Between-dive summary statistics
% 2) Between-dive bursts

clear all, close all
dir_in = '../data/processed/ornitela_bursts';
file_out = '../data/processed/between_dive_intervals.mat';
files = dir(fullfile(dir_in,'*.mat'));

bdive = struct('duration',{},'ngps',{},'nburst',{},...
               'dn_start',{},'dn_end',{},'gps',{},'bursts',{});

nd = 0; % dive counter
duration_max = 60*10; % seconds

for i = 1:length(files)
    % Load file, check for dive data structure(s)
    f_in = fullfile(files(i).folder,files(i).name);
    m = matfile(f_in);
    varlist = who(m);
    varlist = setdiff(varlist,{'dive_stats','bottom_segments'});
    didx = find(contains(varlist,'d')); % dive structures
    load(f_in,'gps');
    fprintf('\r%s [%d of %d]',files(i).name,i,length(files));

    % Load burst data
    btypes = varlist(~contains(varlist,'d') & contains(varlist,'hz'));
    bursts = load(f_in,btypes{:});

    % Count dives
    for ii = 1:length(didx)

        dtype = varlist{didx(ii)};
        tmp = load(f_in,dtype);
        dives = tmp.(dtype); clear tmp

        if max(dives.num) > 1
            dive_start = [1;1+find(diff(dives.num)>0)];
            dive_end = [find(diff(dives.num)>0); length(dives.num)];
            for d = 1:max(dives.num)-1

                i1 = dive_end(d); % end of dive
                i2 = dive_start(d+1); % start of next dive

                % compute duration of between-dive interval
                dur = range(dives.dn([i1 i2]))*86400;

                %% Extract sub-fields only if the interval is short enough
                if dur <= duration_max
                    nd = nd + 1; % increment dive counter;
                    bdive(nd).dn_start = dives.dn(i1);
                    bdive(nd).dn_end = dives.dn(i2);
                    bdive(nd).duration = dur;

                    % identify GPS fixes in interval
                    igps = gps.dn>dives.dn(i1) & gps.dn<dives.dn(i2);

                    % count these
                    bdive(nd).ngps = sum(igps);

                    % store them
                    if sum(igps) > 0
                        bdive(nd).gps = structfun(@(s) s(igps), gps, 'uni',false);
                    end

                    % initialize burst counter
                    bdive(nd).nburst = 0;

                    % identify other sensor bursts in the interval
                    for ib = 1:length(btypes)
                        iburst = bursts.(btypes{ib}).dn >= dives.dn(i1) & bursts.(btypes{ib}).dn <= dives.dn(i2);
                        if sum(iburst)>0
                            bdive(nd).bursts.(btypes{ib}) = structfun(@(s) s(iburst,:), bursts.(btypes{ib}), 'uni',false);
                            bdive(nd).nburst = bdive(nd).nburst + 1;
                        end
                    end
                end
            end
        end
    end % loop over dive burst types
end % loop over files
fprintf('\n')
save('-v7.3',file_out,'bdive')
