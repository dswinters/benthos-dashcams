#!/usr/bin/env bash

# Path to installed config file
config=/usr/local/DASHCAMS/ornitela_config.yaml

# Copy deployment field data csv
local=$(yq e .field_data_local $config)
remote=$(yq e .field_data_remote $config)
rclone_conf=$(yq e .rclone_config $config)
echo "Copying $remote to $local"
rclone --config $rclone_conf copyto "box:$remote" "$local" -v
