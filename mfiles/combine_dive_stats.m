function combine_dive_stats()

dir_in = '../data/processed/ornitela_bursts';
file_out = '../data/processed/ornitela_dives.csv';
files = dir(fullfile(dir_in,'*.mat'));
first = true;

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
