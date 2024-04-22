docker-restic-backup
----

Run restic backups of labeled docker volumes.

Volumes with the `backup: true` label will be backed up to restic repository


```yaml
---
volumes:
  restic_backup_cache:
  redis_data:
    labels:
      backup: true

services:
  redis:
    image: docker.io/redis/redis-stack-server
    environment:
      - TZ=America/Chicago
    volumes:
      - redis_data:/data

  volume_backup:
    image: ghcr.io/rohirrimrider/docker-restic-backup-volume:latest
    hostname: volume_backup
    environment:
      # https://restic.readthedocs.io/en/latest/040_backup.html#environment-variables
      - RESTIC_PASSWORD=mypassword
      - B2_ACCOUNT_ID=whatever
      - B2_ACCOUNT_KEY=whatever
      - RESTIC_REPOSITORY=b2:my-bucket
      - FORGET_FLAGS="--keep-hourly 24 --keep-daily 30 --keep-monthly 12 --prune"
      - "CRON_SCHEDULE=12 * * * *"
      - RESTIC_CACHE_DIR=/cache
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
      - restic_backup_cache:/cache

```
