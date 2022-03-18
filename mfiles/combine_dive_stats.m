function combine_dive_stats()

dir_in = '/home/DASHCAMS/data_processed/ornitela_bursts';
file_out = '/home/DASHCAMS/data_processed/ornitela_dives.csv';
files = dir(fullfile(dir_in,'*.mat'));
first = true;

dive_stats = [];
for i = 1:length(files)
    load(fullfile(files(i).folder,files(i).name),'dive_stats');
    if ~isempty(dive_stats)
        disp(files(i).name)
        if first
            writetable(dive_stats,file_out);
            first = false;
        else
            writetable(dive_stats,file_out,'WriteMode','Append');
        end
    end
end
