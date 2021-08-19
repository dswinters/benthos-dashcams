% Mask out-of-deployment times given a list of datenums and Ornitela tag IDs.
% inputs: dn - datenum vector
%         id - tag id vector (numeric)
% output: yn - binary mask, true for times within deployments
function yn = is_in_deployment(dn,id,location);

% Deployment file
fdata_csv = '../data/DASHCAMS_Deployment_Field_Data.csv';
opts = detectImportOptions(fdata_csv);

% Read tag deployment times
opts.SelectedVariableNames = {
    'Capture_Site',
    'TagManufacture',
    'TagSerialNumber',
    'DeploymentStartDatetime',
    'DeploymentEndDatetime_UTC'};
fdata = readtable(fdata_csv,opts);

% Filter to Ornitela
fdata = fdata(strcmp(fdata.TagManufacture,'Ornitela'),:);

% Filter to location
if nargin > 2
    switch location
      case 'CRE'
        locs = {'Columbia River'};
      case 'MI'
        locs = {'Middleton Island AK'};
      case 'UAE'
        locs = {'Butina Island UAE', 'Siniya Island UAE'};
      case 'LI' % FIXME: Manually added these
        yn = id==202074 & dn > datenum([2021 05 21 15 58 00]) | ...
             id==203022 & dn > datenum([2021 05 21 15 55 00]) | ...
             id==203037 & dn > datenum([2021 05 31 12 27 00]);
        return
    end
    fdata = fdata(ismember(fdata.Capture_Site,locs),:);
end

yn = false(size(dn));
if ischar(id);
    id = str2num(id);
end
uid = unique(id);
for i = 1:length(uid)
    % Get deployment start/end times for id
    deps = fdata(fdata.TagSerialNumber == uid(i),:);
    dn0 = deps.DeploymentStartDatetime;
    dn1 = deps.DeploymentEndDatetime_UTC;

    % Add century, convert to datenum
    dn0.Year = dn0.Year + 2000;
    dn1.Year = dn1.Year + 2000;
    dn0 = datenum(dn0);
    dn1 = datenum(dn1);

    % NaT --> not recorded --> undetermined end-time
    dn1(isnan(dn1)) = inf;

    % Set yn to true for each dn within deployments
    m = id==uid(i); % mask to this id
    for ii = 1:length(dn1)
        yn(m) = yn(m) | (dn(m) >= datenum(dn0(ii)) & dn(m) <= datenum(dn1(ii)));
    end
end

% FIXME: Manually added LI deployments
if nargin < 2
    yn = yn | ...
         id==202074 & dn > datenum([2021 05 21 15 58 00]) | ...
         id==203022 & dn > datenum([2021 05 21 15 55 00]) | ...
         id==203037 & dn > datenum([2021 05 31 12 27 00]);
end
