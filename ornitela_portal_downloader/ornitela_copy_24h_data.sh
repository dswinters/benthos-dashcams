#!/usr/bin/env bash

# Get rclone config info from our config file
config=/usr/local/DASHCAMS/ornitela_config.yaml
rclone_conf=$(yq -r .rclone_config $config)

# Copy data
local=/home/DASHCAMS/data_raw/ornitela_last24h
remote=DASHCAMS/data/ornitela_last24h

echo "Syncing $local to box:$remote"
rclone --config $rclone_conf sync "$local" "box:$remote"
