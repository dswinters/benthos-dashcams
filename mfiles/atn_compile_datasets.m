%% atn_compile_datasets.m
% Usage: atn_compile_datasets
% Description: Compile monthly Ornitela data files into project sub-directories
%              for transfer to ATN.
% Inputs: None
% Outputs: None
%
% Author: Dylan Winters
% Created: 2022-01-14

clear all, close all

fdata_csv = '/home/DASHCAMS/data_raw/metadata/DASHCAMS_Deployment_Field_Data.csv';
dir_out = '/home/DASHCAMS/data_raw/ornitela_for_ATN';
opts = detectImportOptions(fdata_csv);
overwrite = false; % copy files if they already exist in target directory?

% Read tag deployment metadata
opts.SelectedVariableNames = {
    'Project_ID',
    'Capture_Site',
    'TagManufacture',
    'TagSerialNumber',
    'DeploymentStartDatetime',
    'DeploymentEndDatetime_UTC',
    'Deployment_End_Notes',
                   };
fdata = readtable(fdata_csv,opts);

% Identify projects with Ornitela tags
IDs = unique(fdata.Project_ID);
has_ornitela = false(size(IDs));
for i = 1:length(IDs)
    idx = strcmp(fdata.Project_ID,IDs{i});
    has_ornitela(i) = any(idx & strcmp(lower(fdata.TagManufacture), 'ornitela'));
end
IDs = IDs(has_ornitela);

% Ensure output directories exist
fmts = {'gps', 'gps_sensors_v2'};
for i = 1:length(IDs)
    pdir_out = fullfile(dir_out,IDs{i});
    for j = 1:length(fmts)
        dirname = fullfile(pdir_out,fmts{j});
        if ~exist(dirname,'dir')
            mkdir(dirname)
        end
    end
end

%% Copy files

% Do all of this for both the 'gps' and 'gps_sensors_v2' formats
for i = 1:length(fmts)

    % Get the serial number and date range for every file
    files = dir(['/home/DASHCAMS/data_raw/ornitela_' fmts{i}]);
    files = files(~ismember({files.name},{'.','..'}));
    strparts = cellfun(@(c) strsplit(c,{'_','.'}), {files.name},'uni',false);
    serialnum = cellfun(@(c) str2num(c{1}), strparts)';
    year = cellfun(@(c) str2num(c{2}), strparts);
    month = cellfun(@(c) str2num(c{3}), strparts);
    file_dn_range = [datenum([year(:) month(:), 0*year(:) + [1 0 0 0]]),...
                     datenum([year(:) month(:)+1, 0*year(:) + [1 0 0 0]])];


    % For each project, identify tags deployed
    for j = 1:length(IDs)
        pdir_out = fullfile(dir_out,IDs{j},fmts{i});
        IDidx = strcmp(fdata.Project_ID,IDs{j});
        tags = unique(fdata.TagSerialNumber(IDidx));

        % For each tag used, identify deployments
        for t = 1:length(tags)
            deps = find(IDidx & fdata.TagSerialNumber==tags(t));

            % Finally, for each deployment of the tag, copy files containing
            % dates within the deployment's duration
            for d = 1:length(deps)

                % Get deployment time ranges
                dep_start = datenum(fdata.DeploymentStartDatetime(deps(d)));
                dep_end = datenum(fdata.DeploymentEndDatetime_UTC(deps(d)));
                % Fix incomplete datestamps
                dn0 = datenum([2000 0 0 0 0 0]);
                dep_start(dep_start<dn0) = dep_start(dep_start<dn0) + dn0;
                dep_end(dep_end<dn0) = dep_end(dep_end<dn0) + dn0;
                % Set end time of ongoing deployments to inf
                if isnan(dep_end) | strcmp(fdata.Deployment_End_Notes{deps(d)},'***Active')
                    dep_end = inf;
                end

                % Want to copy files satisfying:
                % - serial number matches deployment AND
                % - deployment has defined start date AND
                %   - deployment starts within file
                %   - deployment ends within file
                %   - file is fully contained in deployment
                do_copy = serialnum == tags(t) & ...
                          ((dep_start >= file_dn_range(:,1) & dep_start <= file_dn_range(:,2)) | ...
                           (dep_end   >= file_dn_range(:,1) & dep_end   <= file_dn_range(:,2)) | ...
                           (file_dn_range(:,1) >= dep_start & file_dn_range(:,2) <= dep_end));

                if sum(do_copy) > 0
                    fprintf('%s deployment: %d starting %s [%d files]\n',...
                            IDs{j},tags(t),datestr(dep_start),sum(do_copy));
                end
                % Copy all files that should be copied
                fidx = find(do_copy);
                for f = 1:length(fidx)
                    f_out = fullfile(pdir_out,files(fidx(f)).name);
                    if ~exist(f_out,'file') || overwrite
                        copyfile(fullfile(files(fidx(f)).folder,files(fidx(f)).name),...
                                 f_out);
                        fprintf('   Copied %s to %s\n',files(fidx(f)).name,f_out);
                    else
                        fprintf('   %s exists; skipping\n',f_out);
                    end
                end

            end
        end
    end
end
