#!/usr/bin/env bash

# Install systemd services/timers
cp services/dashcams-ornitela-download-month.service /etc/systemd/system
cp services/dashcams-ornitela-download-month.timer /etc/systemd/system
cp services/dashcams-ornitela-download-prev-month.service /etc/systemd/system
cp services/dashcams-ornitela-download-prev-month.timer /etc/systemd/system


# Copy configuration and executables
mkdir -p /usr/local/DASHCAMS
cp config.yaml /usr/local/DASHCAMS/ornitela_config.yaml
cp download_month.py /usr/local/DASHCAMS
cp portal_box_sync.sh /usr/local/DASHCAMS
cp -r classes /usr/local/DASHCAMS

# Enable timer
systemctl enable dashcams-ornitela-download-month.timer
systemctl enable dashcams-ornitela-download-prev-month.timer
systemctl restart dashcams-ornitela-download-month.timer
systemctl restart dashcams-ornitela-download-prev-month.timer
