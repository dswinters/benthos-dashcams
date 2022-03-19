clear all, close all

% Get list of files
dir_in = '/home/DASHCAMS/data_raw/ornitela_ftp';
files = dir(fullfile(dir_in,'*.csv'));

% Filter to files from last N days
ndays = 1;
files = files([files.datenum] > (now-ndays));

% Don't warn about field names with spaces
warning('off','MATLAB:table:ModifiedAndSavedVarnames');

fields_to_check = {'ext_temperature_C','depth_m'};
types = {'double','double'};

failures = struct();
nfail = 0;


for i = 1:length(files)
    % Get field names from within file
    fname = fullfile(files(i).folder, files(i).name);
    opts = detectImportOptions(fname);

    % Check for fields in the list that we care about
    fld_idx = ismember(opts.VariableNames,fields_to_check);

    % Get tag ID and time of file
    fname_parts = strsplit(files(i).name,'_');
    id = str2num(fname_parts{1});
    dtime = datenum([fname_parts{3:4}],'yyyymmddHHMMSS');

    if any(fld_idx); % If there are any fields that we want to check

        % Only parse variables that we want to check
        opts.SelectedVariableNames = opts.VariableNames(fld_idx);
        % And tell MATLAB what to parse them as
        idx = ismember(opts.SelectedVariableNames,fields_to_check);
        opts = setvartype(opts,fields_to_check(idx),types(idx));

        t = readtable(fname,opts);

        % Check if temperature exceeds 50 degrees
        if any(t.ext_temperature_C > 50)
            reason = "Temperature exceeded 50 deg C";
            nfail = nfail+1;
            failures(nfail).id = id;
            failures(nfail).reason = reason;
            failures(nfail).time = dtime;
        end

        % Check if temperature is below freezing
        if any(t.ext_temperature_C < 0)
            reason = "Temperature below 0 deg C";
            nfail = nfail+1;
            failures(nfail).id = id;
            failures(nfail).reason = reason;
            failures(nfail).time = dtime;
        end

        % Check if depth exceeds 100 m
        if any(t.depth_m > 100)
            reason = "Depth exceeded 100 m";
            nfail = nfail+1;
            failures(nfail).id = id;
            failures(nfail).reason = reason;
            failures(nfail).time = dtime;
        end

        % Can easily add more checks here.
    end

end

if length(failures) > 0
    fprintf('%d failures in last %d day(s):\n', length(failures), ndays)
    for i = 1:length(failures)
        fprintf('%d: %s on or around %s\n',...
                failures(i).id, failures(i).reason, datestr(failures(i).time))
    end
end
