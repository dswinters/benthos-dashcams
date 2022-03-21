#!/usr/bin/env python

import sys
import yaml
from slack_sdk import WebClient

# Get Slack configuration
config = yaml.safe_load(open("/usr/local/DASHCAMS/slack.yaml"))

# Initialize connection to Slack
client = WebClient(token=config['token'])

# Post a message
response = client.chat_postMessage(
    channel=config['channel'],
    text=sys.argv[1],
)
