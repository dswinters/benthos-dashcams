function combine_locations()

dir_in = '../data/processed/ornitela_bursts';
file_out = '../data/processed/ornitela_gps.csv';
files = dir(fullfile(dir_in,'*.mat'));
first = true;

gps = [];
for i = 1:length(files)
    load(fullfile(files(i).folder,files(i).name),'gps');
    if ~isempty(gps)
        id = ones(size(gps.dn))*str2num(extractBefore(files(i).name,'_'));
        gps = table(id, gps.dn, gps.lat, gps.lon,'variablenames',{'id','time','lat','lon'});
        gps.time = datetime(gps.time,'convertfrom','datenum');
        disp(files(i).name)
        if first
            writetable(gps,file_out);
            first = false;
        else
            writetable(gps,file_out,'WriteMode','Append');
        end
    end
end
