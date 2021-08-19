#!/usr/bin/env bash


# Do MATLAB processing
echo "Running MATLAB processing..."
/usr/local/bin/matlab -nodisplay -r "run('/home/dw/projects/DASHCAMS/mfiles/run_after_download.m')" > /dev/null

# Sync files to Box with rclone

# Path to installed config file
config=/usr/local/DASHCAMS/ornitela_config.yaml

# Copy raw GPS+SENSORS_V2
local=$(yq -r .gps_sensors_v2_local $config)
remote=$(yq -r .gps_sensors_v2_remote $config)
rclone_conf=$(yq -r .rclone_config $config)
echo "Syncing $local to box:$remote"
rclone --config $rclone_conf sync "$local" "box:$remote"

# Copy raw GPS
local=$(yq -r .gps_local $config)
remote=$(yq -r .gps_remote $config)
echo "Syncing $local to box:$remote"
rclone --config $rclone_conf sync "$local" "box:$remote"

# Copy dives file
local="/home/dw/projects/DASHCAMS/data/processed/ornitela_dives.csv"
remote="DASHCAMS/data/Processed"
echo "Syncing $local to box:$remote"
rclone --config $rclone_conf copy "$local" "box:$remote"

# Copy locations file
local="/home/dw/projects/DASHCAMS/data/processed/ornitela_gps.csv"
remote="DASHCAMS/data/Processed"
echo "Syncing $local to box:$remote"
rclone --config $rclone_conf copy "$local" "box:$remote"

# Copy between_dive_invervals file
local="/home/dw/projects/DASHCAMS/data/processed/between_dive_intervals.mat"
remote="DASHCAMS/data/Processed"
echo "Syncing $local to box:$remote"
rclone --config $rclone_conf copy "$local" "box:$remote"


# Copy processed data files
local="/home/dw/projects/DASHCAMS/data/processed/ornitela_bursts"
remote="DASHCAMS/data/Processed/ornitela_bursts"
echo "Syncing $local to box:$remote"
rclone --config $rclone_conf sync "$local" "box:$remote"
