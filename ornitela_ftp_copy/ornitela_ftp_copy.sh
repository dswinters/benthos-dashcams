#!/usr/bin/env bash

# Watch for incoming FTP data from Ornitela and push it to Box.
ftp_dir=/home/server/ftp/incoming/ornitela
box_dir=box:DASHCAMS/data/ornitela_ftp_data
local_dir=/home/DASHCAMS/data_raw/ornitela_ftp

config=/usr/local/DASHCAMS/ornitela_config.yaml
rclone_conf=$(yq -r .rclone_config $config)

find $ftp_dir -newermt "-61 minutes" -type f \
  -exec cp {} $local_dir \; \
  -exec rclone --config $rclone_conf copy {} $box_dir \; \
  -exec echo {} \;

# The below approach is great, but unfortunately doesn't work with NFS drives...
# inotifywait -m $ftp_dir -e create -e moved_to |
#   while read dir action file; do
#     echo "$(date +"%Y-%m-%d_%T") ${file}"
#     rclone copy --ignore-existing "${ftp_dir}/${file}" "${box_dir}"
#     cp "${ftp_dir}/${file}" "${local_dir}/${file}"
#   done
