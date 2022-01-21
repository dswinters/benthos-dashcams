clear all, close all

dir_in = '../data/processed/ornitela_bursts/';
files = dir(fullfile(dir_in,'*.mat'));

dn = [];
id = [];
dive_stats = [];

for i = 1:length(files)
    tmp = load(fullfile(files(i).folder,files(i).name),'gps','dive_stats');
    dn = cat(1,dn,tmp.gps.dn);
    id = cat(1,id,ones(size(tmp.gps.dn))*str2num(extractBefore(files(i).name,'_')));

    if ~isempty(tmp.dive_stats)
        if isempty(dive_stats)
            dive_stats = tmp.dive_stats;
        else
            dive_stats = cat(1,dive_stats,tmp.dive_stats);
        end
    end
end

locs = {'CRE','MI','UAE','LI'};
for i = 1:length(locs)
    iloc = is_in_deployment(dn,id,locs{i});

    % GPS
    dnl = dn(iloc);
    idl = id(iloc);
    uid = unique(idl);
    disp(sprintf('%d tags in %s',length(uid),locs{i}));
    dn_range = nan(size(uid));

    % Dives
    dnd = datenum(dive_stats.time);
    durd = dive_stats.bottom_dur;
    idd = dive_stats.tag;
    ilocd = is_in_deployment(dnd,idd,locs{i});
    dndl = dnd(ilocd);
    durdl = durd(ilocd);
    iddl = idd(ilocd);
    dive_count = nan(size(uid));


    for ii = 1:length(uid)
        dn_range(ii) = range(dnl(idl==uid(ii)));
        dive_count(ii) = sum(iddl==uid(ii));
        bdive_count(ii) = sum(iddl==uid(ii) & durdl>0);
        disp(sprintf('  %d: %.2f days, %d dives [%d benthic]',...
                     uid(ii),dn_range(ii), dive_count(ii), bdive_count(ii)));
    end
    disp(sprintf('Max duration: %.2f days', max(dn_range)))
    disp(sprintf('Mean duration: %.2f days (std=%.2f)', mean(dn_range), std(dn_range)))
    disp(sprintf('Total dives: %d', sum(dive_count)))
    disp(sprintf('Benthic dives: %d', sum(bdive_count)))
    disp(sprintf('Benthic rate: %.2f', sum(bdive_count)/sum(dive_count)))
    disp(sprintf('Dives/tag: %.2f', sum(dive_count)/length(uid)))
    disp('')
end
