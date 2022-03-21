#!/usr/bin/env bash

/usr/local/bin/matlab -nodisplay -r "run('/home/DASHCAMS/git/benthos-dashcams/mfiles/tag_failure_checks.m')" > /dev/null
failures="$(cat /home/DASHCAMS/tag_failures.txt)"

if [ ! -z "$failures" ]; then
  /usr/local/DASHCAMS/send_slack_message.py "$failures"
fi
