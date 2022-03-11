#!/usr/bin/env bash

# Install systemd services/timers
sudo cp ornitela_portal_downloader/services/dashcams-ornitela-download-month.service      /etc/systemd/system
sudo cp ornitela_portal_downloader/services/dashcams-ornitela-download-month.timer        /etc/systemd/system
sudo cp ornitela_portal_downloader/services/dashcams-ornitela-download-prev-month.service /etc/systemd/system
sudo cp ornitela_portal_downloader/services/dashcams-ornitela-download-prev-month.timer   /etc/systemd/system
sudo cp ornitela_ftp_copy/dashcams-ornitela-ftp-copy.service                              /etc/systemd/system
sudo cp ornitela_ftp_copy/dashcams-ornitela-ftp-copy.timer                                /etc/systemd/system
sudo cp services/dashcams-download-field-data.service                                     /etc/systemd/system
sudo cp services/dashcams-download-field-data.timer                                       /etc/systemd/system
sudo cp services/dashcams-run-R-analysis.service                                          /etc/systemd/system
sudo cp services/dashcams-run-R-analysis.timer                                            /etc/systemd/system


# Copy configuration and executables
sudo mkdir -p                                                /usr/local/DASHCAMS
sudo cp config.yaml                                          /usr/local/DASHCAMS/ornitela_config.yaml
sudo cp ornitela_portal_downloader/download_month.py         /usr/local/DASHCAMS
sudo cp ornitela_portal_downloader/ornitela_post_download.sh /usr/local/DASHCAMS
sudo cp ornitela_portal_downloader/download_last_24h.py      /usr/local/DASHCAMS
sudo cp -r ornitela_portal_downloader/classes                /usr/local/DASHCAMS
sudo cp ornitela_ftp_copy/ornitela_ftp_copy.sh               /usr/local/DASHCAMS
sudo cp services/dashcams-download-field-data.sh             /usr/local/DASHCAMS
sudo cp services/dashcams-run-R-analysis.sh                  /usr/local/DASHCAMS


# Enable timers
sudo systemctl enable dashcams-ornitela-download-month.timer
sudo systemctl enable dashcams-ornitela-download-prev-month.timer
sudo systemctl enable dashcams-ornitela-ftp-copy.timer
sudo systemctl enable dashcams-download-field-data.timer
sudo systemctl enable dashcams-run-R-analysis.timer

sudo systemctl restart dashcams-ornitela-download-month.timer
sudo systemctl restart dashcams-ornitela-download-prev-month.timer
sudo systemctl restart dashcams-ornitela-ftp-copy.timer
sudo systemctl restart dashcams-download-field-data.timer
sudo systemctl restart dashcams-run-R-analysis.timer
