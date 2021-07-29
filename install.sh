#!/usr/bin/env bash

# Install systemd services/timers
sudo cp ornitela_portal_downloader/services/dashcams-ornitela-download-month.service      /etc/systemd/system
sudo cp ornitela_portal_downloader/services/dashcams-ornitela-download-month.timer        /etc/systemd/system
sudo cp ornitela_portal_downloader/services/dashcams-ornitela-download-prev-month.service /etc/systemd/system
sudo cp ornitela_portal_downloader/services/dashcams-ornitela-download-prev-month.timer   /etc/systemd/system
sudo cp ornitela_ftp_copy/dashcams-ornitela-ftp-copy.service   /etc/systemd/system
sudo cp ornitela_ftp_copy/dashcams-ornitela-ftp-copy.timer     /etc/systemd/system


# Copy configuration and executables
sudo mkdir -p /usr/local/DASHCAMS
sudo cp config.yaml                                   /usr/local/DASHCAMS/ornitela_config.yaml
sudo cp ornitela_portal_downloader/download_month.py  /usr/local/DASHCAMS
sudo cp ornitela_portal_downloader/portal_box_sync.sh /usr/local/DASHCAMS
sudo cp -r ornitela_portal_downloader/classes         /usr/local/DASHCAMS
sudo cp ornitela_ftp_copy/ornitela_ftp_copy.sh        /usr/local/DASHCAMS

# Enable timers
sudo systemctl enable dashcams-ornitela-download-month.timer
sudo systemctl enable dashcams-ornitela-download-prev-month.timer
sudo systemctl enable dashcams-ornitela-ftp-copy.timer

sudo systemctl restart dashcams-ornitela-download-month.timer
sudo systemctl restart dashcams-ornitela-download-prev-month.timer
sudo systemctl restart dashcams-ornitela-ftp-copy.timer
