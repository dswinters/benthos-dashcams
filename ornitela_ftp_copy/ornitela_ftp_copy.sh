#!/usr/bin/env bash

# Watch for incoming FTP data from Ornitela and push it to Box.
ftp_dir=/home/server/ftp/incoming/ornitela
box_dir=box:DASHCAMS/data/ornitela_ftp_data
local_dir=/home/DASHCAMS/data_raw/ornitela_ftp
tmp_file_list=/home/DASHCAMS/ornitela_new_ftp.txt

config=/usr/local/DASHCAMS/ornitela_config.yaml
rclone_conf=$(yq e .rclone_config $config)

# Find new files
find $ftp_dir -newermt "-61 minutes" -type f -printf "%f\n"> $tmp_file_list

# Copy them to local storage
for file in $(<$tmp_file_list); do
  if [[ $file == *.csv ]]; then
    echo $file
    cp "$ftp_dir/$file" "$local_dir/$file"
  fi
done

# Copy new files to Box
echo "Copying new files to $box_dir"
rclone --config $rclone_conf --include-from $tmp_file_list copy $local_dir/ $box_dir
rm $tmp_file_list

# The below approach is great, but unfortunately doesn't work with NFS drives...
# inotifywait -m $ftp_dir -e create -e moved_to |
#   while read dir action file; do
#     echo "$(date +"%Y-%m-%d_%T") ${file}"
#     rclone copy --ignore-existing "${ftp_dir}/${file}" "${box_dir}"
#     cp "${ftp_dir}/${file}" "${local_dir}/${file}"
#   done
