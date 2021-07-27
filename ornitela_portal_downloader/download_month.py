#!/usr/bin/env python
"""
usage: download_month.py [-h] [--year [YEAR]] [--month [MONTH]] [serials ...]

Download one month of data from the given tag.

positional arguments:
  serials          Tag serial number(s) (int) (default: all)

optional arguments:
  -h, --help       show this help message and exit
  --year [YEAR]    year from which to download data (int) (default: current)
  --month [MONTH]  month from which to download data (int) (default: current)
"""
import argparse
from datetime import datetime
import yaml
from classes.Ornitela_Downloader import Ornitela_Downloader

# Get current month and year
year = datetime.now().year
month = datetime.now().month

# Get user configuration
config = yaml.safe_load(open("/usr/local/DASHCAMS/ornitela_config.yaml"))
# Parse arguments
parser = argparse.ArgumentParser(description="Download one month of data from the given tag.",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('--year', type=int, default=year, nargs='?', help='year from which to download data (int)')
parser.add_argument('--month', type=int, default=month, nargs='?', help='month from which to download data (int)')
parser.add_argument('serials', type=int, nargs='*', default=None, help='Tag serial number(s) (int)')
args = parser.parse_args()

# Download data
portal = Ornitela_Downloader(config)

# Default to all serialnumbers if none are specified
serials = args.serials or config['tags'].keys()

# Download previous month if month is -1
if args.month == -1:
    args.month = month - 1
if args.month == 0:
    args.month = 12
    args.year = year - 1

# Download data
for s in serials:
    portal.download_month(s, args.year, args.month)
