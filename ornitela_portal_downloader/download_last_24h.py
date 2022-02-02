#!/usr/bin/env python

from classes.Ornitela_Downloader import Ornitela_Downloader
from datetime import datetime
from datetime import timedelta
import argparse
import yaml

# Get user configuration
config = yaml.safe_load(open("/usr/local/DASHCAMS/ornitela_config.yaml"))

# Parse arguments
parser = argparse.ArgumentParser(description="Download last 24h of data from the given tag.",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('serials', type=int, nargs='*', default=None, help='Tag serial number(s). All tags if none specified.')
args = parser.parse_args()
serials = args.serials or config['tags'].keys()

# Initialize downloader
portal = Ornitela_Downloader(config)
to_date = datetime.now()
from_date = to_date - timedelta(days=1)

# Download data
fdir = "/home/DASHCAMS/data_raw/ornitela_last24h"
for s in serials:
    fname = "%s/%06d_24h.csv" % (fdir,s)
    portal.download_date_range(s, from_date, to_date, fname)
