#!/bin/bash
set -ue

echo "${CRON_SCHEDULE} /run.sh" > /crontab.txt
echo "Running scheduled cron: ${CRON_SCHEDULE}"
/usr/bin/crontab /crontab.txt
exec /usr/sbin/crond -f -l 8
