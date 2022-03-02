#!/usr/bin/env bash

# TODO: We no longer need the last 24hrs of Ornitela data; since we are now
# using the FTP data as a source.

# Get rclone config info from our config file
config=/usr/local/DASHCAMS/ornitela_config.yaml
rclone_conf=$(yq -r .rclone_config $config)

# Run Rachael's R processing
dir_in=/home/DASHCAMS/data_raw/ornitela_ftp/
dir_out=/home/DASHCAMS/data_processed/zTagStatus/
depdat=/home/DASHCAMS/data_raw/metadata/DASHCAMS_Deployment_Field_Data.csv

Rscript --vanilla /home/dw/projects/DASHCAMS/repos/CormOcean/TagStatus_1wk.R "$dir_in" "$depdat" "$dir_out"
# Rscript --vanilla /home/dw/projects/DASHCAMS/repos/CormOcean/TagStatus_24hr.R "$dir_in" "$depdat" "$dir_out"

# Copy data
local=/home/DASHCAMS/data_raw/ornitela_last24h
remote=DASHCAMS/data/ornitela_last24h

echo "Syncing $local to box:$remote"
rclone --config $rclone_conf sync "$local" "box:$remote"

# Copy data
local=/home/DASHCAMS/data_processed/zTagStatus
remote=DASHCAMS/zTagStatus

echo "Syncing $local to box:$remote"
rclone --config $rclone_conf sync "$local" "box:$remote"
