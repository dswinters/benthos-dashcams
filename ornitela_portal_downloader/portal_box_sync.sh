#!/usr/bin/env bash

# Path to installed config file
config=/usr/local/DASHCAMS/ornitela_config.yaml

# Copy GPS+SENSORS_V2
local=$(yq -r .gps_sensors_v2_local $config)
remote=$(yq -r .gps_sensors_v2_remote $config)
rclone_conf=$(yq -r .rclone_config $config)
echo "Syncing $local to box:$remote"
rclone --config $rclone_conf sync --progress "$local" "box:$remote"

# Copy GPS
local=$(yq -r .gps_local $config)
remote=$(yq -r .gps_remote $config)
echo "Syncing $local to box:$remote"
rclone --config $rclone_conf sync --progress "$local" "box:$remote"
