% Extract sensor bursts using the GPS+SENSORS_V2 data format and
% ornitela_v2_timestamp_correction.m.
%
% See ../data/processed/ornitela_bursts/readme.txt
%
clear all, close all
warning('off','MATLAB:table:ModifiedAndSavedVarnames');
dir_in = '/home/DASHCAMS/data_raw/ornitela_gps_sensors_v2';
dir_out = '../data/processed/ornitela_bursts';
files = dir(fullfile(dir_in,'*.csv'));
overwrite = true;

% Get unique tag IDs
ids = unique(cellfun(@(c) c(1:6),{files.name},'uniformoutput',false));

% Define how we want to read the .csv files
read_fields = {'UTC_date'           , 'datetime';
               'UTC_time'           , 'datetime';
               'datatype'           , 'categorical';
               'Latitude'           , 'double';
               'Longitude'          , 'double';
               'mag_x'              , 'double';
               'mag_y'              , 'double';
               'mag_z'              , 'double';
               'acc_x'              , 'double';
               'acc_y'              , 'double';
               'acc_z'              , 'double';
               'milliseconds'       , 'double';
               'depth_m'            , 'double';
               'conductivity_mS_cm' , 'double';
               'ext_temperature_C'  , 'double';
               'satcount'           , 'int8';
               'U_bat_mV'           , 'double';
               'bat_soc_pct'        , 'double';
               'solar_I_mA'         , 'double';
               'hdop'               , 'double';
               'MSL_altitude_m'     , 'double';
               'speed_km_h'         , 'double';
               'direction_deg'      , 'double';
               'int_temperature_C'  , 'double';
               'light'              , 'double';
               'altimeter_m'        , 'double'};

mb_total = sum([files.bytes])/2^20;
mb_proc = 0;
nf_proc = 0;
for nid = 1:length(ids)
    id_idx = find(contains({files.name},ids{nid})); % file indices associated w/ tag id
    idfiles = files(id_idx);
    idfilenames = fullfile(dir_in,{files(id_idx).name});
    for f = 1:length(idfilenames)
        [~,fname,~] = fileparts(idfilenames{f});
        f_out = fullfile(dir_out,[fname '.mat']);
        f_out_info = dir(f_out);
        updated = isempty(f_out_info) || files(id_idx(f)).datenum > f_out_info.datenum || overwrite;

        opts = detectImportOptions(idfilenames{f});
        if updated && sum(ismember(opts.VariableNames,read_fields(:,1))) > 0

            % Set variable types according cell array defined above and tell readtable to
            % only read these variables:
            opts = setvartype(opts,read_fields(:,1),read_fields(:,2));
            opts.SelectedVariableNames = read_fields(:,1);

            % Read the raw data and separate into burst types
            fprintf('\rReading %s...', idfilenames{f})
            T = readtable(idfilenames{f},opts);

            % Remove non-unique rows
            nrows = height(T);
            T = unique(T,'stable');
            if nrows - height(T) > 0
                fprintf('\nRemoved %d non-unique entries from %s\n',nrows-height(T),fname)
            end
            [dn, burst_num, burst_type_num, burst_types] = ornitela_v2_timestamp_correction(T);

            % Initialize output structure, create GPS sub-structure
            fprintf('\rProcessing GPS')
            tag = struct();
            tag.gps = struct();
            gps_types = {'GPS','GPSD','GPSS','GPSF','GPSB'};
            igps = ismember(T.datatype, categorical(gps_types));
            tag.gps.dn = dn(igps);
            tag.gps.lat = T.Latitude(igps);
            tag.gps.lon = T.Longitude(igps);
            tag.gps.satcount          = T.satcount(igps);
            tag.gps.U_bat_mV          = T.U_bat_mV(igps);
            tag.gps.bat_soc_pct       = T.bat_soc_pct(igps);
            tag.gps.solar_I_mA        = T.solar_I_mA(igps);
            tag.gps.hdop              = T.hdop(igps);
            tag.gps.MSL_altitude_m    = T.MSL_altitude_m(igps);
            tag.gps.speed_km_h        = T.speed_km_h(igps);
            tag.gps.direction_deg     = T.direction_deg(igps);
            tag.gps.int_temperature_C = T.int_temperature_C(igps);
            tag.gps.light             = T.light(igps);
            tag.gps.altimeter_m       = T.altimeter_m(igps);

            % Check for any unused fields
            unused_flds = setdiff(cellstr(unique(T.datatype)),...
                                  cat(1,burst_types(:),gps_types(:)));
            unused_flds = unused_flds(~endsWith(unused_flds,{'_START','_END','_ENDINT'}));

            if ~isempty(unused_flds)
                for uf = 1:length(unused_flds)
                    warning('Unused fields found in %s',fname);
                    fprintf('  %s\n',unused_flds{:});
                end
            end

            % Create burst sub-structures
            for b = 1:length(burst_types)
                bname = lower(burst_types{b});
                fprintf('\rProcessing %s [%d of %d]',bname,b,length(burst_types))
                tag.(bname) = struct();
                iburst = burst_type_num == b;

                % Extract all fields for bursts of this type
                tag.(bname).dn                = dn(iburst);
                tag.(bname).num               = burst_num(iburst) - min(burst_num(iburst)) + 1;
                tag.(bname).conductivity      = T.conductivity_mS_cm(iburst);
                tag.(bname).temperature       = T.ext_temperature_C(iburst);
                tag.(bname).depth             = T.depth_m(iburst);
                tag.(bname).mag               = [T.mag_x(iburst), T.mag_y(iburst), T.mag_z(iburst)];
                tag.(bname).acc               = [T.acc_x(iburst), T.acc_y(iburst), T.acc_z(iburst)];
                tag.(bname).satcount          = T.satcount(iburst);
                tag.(bname).U_bat_mV          = T.U_bat_mV(iburst);
                tag.(bname).bat_soc_pct       = T.bat_soc_pct(iburst);
                tag.(bname).solar_I_mA        = T.solar_I_mA(iburst);
                tag.(bname).hdop              = T.hdop(iburst);
                tag.(bname).MSL_altitude_m    = T.MSL_altitude_m(iburst);
                tag.(bname).speed_km_h        = T.speed_km_h(iburst);
                tag.(bname).direction_deg     = T.direction_deg(iburst);
                tag.(bname).int_temperature_C = T.int_temperature_C(iburst);
                tag.(bname).light             = T.light(iburst);
                tag.(bname).altimeter_m       = T.altimeter_m(iburst);
            end

            % Generate dive stats and bottom segments
            id = str2num(extractBefore(idfiles(f).name,'_'));
            [tag.dive_stats, tag.bottom_segments] = proc_dive_stats(tag,id);

            % Save file
            save(f_out,'-struct','tag');
            nf_proc = nf_proc + 1;
            mb_proc = mb_proc + idfiles(f).bytes/2^20;
            fprintf('\rSaved %s [%d of %d] [%.1fMB of %.1fMB]\n',f_out, nf_proc, length(files), mb_proc, mb_total)
        else % if file updated and contains proper fields
            nf_proc = nf_proc + 1;
            mb_proc = mb_proc + idfiles(f).bytes/2^20;
            fprintf('\r%s is up-to-date [%d of %d] [%.1fMB of %.1fMB]\n',f_out, nf_proc, length(files), mb_proc, mb_total)
        end

    end
end
fprintf('\n')

%% Report burst time totals when done processing
dir_in = dir_out;
files = dir(fullfile(dir_in,'*.mat'));

% Initialize variable type and duration array
vars = {};
durs = [];

for i = 1:length(files)
    % Load file and get variable names
    dat = load(fullfile(files(i).folder,files(i).name));
    flds = setdiff(fields(dat),{'gps','dive_stats','bottom_segments'});
    for f = 1:length(flds)
        % Add variable name to list if it doesn't exist
        if ~contains(flds{f},vars);
            vars{end+1} = flds{f};
            durs(end+1) = 0;
        end
        ind = find(strcmp(flds{f},vars));
        % Compute time range of each burst, sum them, add to total
        fdurs = splitapply(@range,dat.(flds{f}).dn,dat.(flds{f}).num);
        durs(ind) = durs(ind) + sum(fdurs);
    end
end


fid = fopen('../data/processed/ornitela_bursts_summary.txt','w');
for i = 1:length(vars)
    fprintf(fid,'|%s|%.2f|\n',vars{i},durs(i));
end

return

%% Count total dives and dives/day
days_total = nan(length(files),1);
dives_total = nan(length(files),1);
for i = 1:length(files)
    % Load file
    f_in = fullfile(files(i).folder,files(i).name);
    m = matfile(f_in);
    varlist = who(m);
    didx = find(contains(varlist,'d')); % dive structures
    load(f_in,'gps');

    % Count days
    tag_days_tot = range(gps.dn);

    % Count dives
    tag_dives_tot = 0;
    for ii = 1:length(didx)
        tmp = load(f_in,varlist{didx(ii)});
        tag_dives_tot = tag_dives_tot + max(tmp.(varlist{didx(ii)}).num);
    end

    % Record
    days_total(i) = tag_days_tot;
    dives_total(i) = tag_dives_tot;
    fprintf('\r%s [%d of %d]: %d dives, %.1f days',files(i).name,i,length(files),tag_dives_tot,tag_days_tot);

end
fprintf(fid,'\n\nTotals:\n');
fprintf(fid,'%.1f Days, %d dives (%.2f dives/day)\n',...
        sum(days_total),sum(dives_total),sum(dives_total)/sum(days_total));
