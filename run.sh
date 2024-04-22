#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

DOCKER_VOLUME_ROOT=${DOCKER_VOLUME_ROOT:-/var/lib/docker/volumes}

set -ueo pipefail

if [ -n "${DEBUG:-}" ]; then
    set -x
fi

# Check if Docker socket is mounted and Docker daemon is accessible
if ! docker info; then
    echo -e "${RED}Failed to connect to Docker daemon. Please ensure Docker socket is mounted.${NC}"
    exit 1
fi

if [ ! -d "${DOCKER_VOLUME_ROOT}" ]; then
    echo -e "${RED}DOCKER_VOLUME_ROOT is not a valid directory. Either mount it to ${DOCKER_VOLUME_ROOT} or set the environment variable.${NC}"
    exit 1
fi

if [ -z "${RESTIC_REPOSITORY:-}" ]; then
    echo -e "${RED}RESTIC_REPOSITORY is not set. Please set the environment variable.${NC}"
    exit 1
fi

if [ -z "${RESTIC_PASSWORD:-}" ]; then
    echo -e "${RED}RESTIC_PASSWORD is not set. Please set the environment variable.${NC}"
    exit 1
fi


# Green text
echo -e "${GREEN}====> Starting volume backup... ${NC}"
docker volume ls --filter label=backup --format "{{.Name}}" | while read -r volume; do
    echo "${GREEN}==> Backing up volume: $volume${NC}"

    # Fetch custom labels from the volume
    pre_command=$(docker volume inspect "$volume" --format '{{ index .Labels "restic.backup.pre-command" }}')
    post_command=$(docker volume inspect "$volume" --format '{{ index .Labels "restic.backup.post-command" }}')
    backup_flags=$(docker volume inspect "$volume" --format '{{ index .Labels "restic.backup.flags" }}')

    # Assume the volume path is under /var/lib/docker/volumes
    volume_path="${DOCKER_VOLUME_ROOT}/$volume/_data"

    # Pre-command execution
    if [ -n "$pre_command" ]; then
        eval "$pre_command" || echo -e "${RED}Pre-command failed for $volume${NC}"
    fi

    # Build restic backup command with flags and excludes
    restic_command="restic backup --tag docker.volume=$volume $backup_flags $volume_path"

    eval "$restic_command" || echo -e "${RED}Backup failed for $volume${NC}"

    if [ -n "$post_command" ]; then
        eval "$post_command" || echo -e "${RED}Post-command failed for $volume${NC}"
    fi

done

echo -e "${GREEN}====> Volumes backup completed. Running forget and prune...${NC}"
if [ -n "${FORGET_FLAGS:-}" ]; then
	eval "restic forget $FORGET_FLAGS" || echo -e "${RED}restic forget failed${NC}"
fi

eval "restic prune ${PRUNE_FLAGS:-}" || echo -e "${RED}Prune failed${NC}"

echo -e "${GREEN}====> Backup and prune completed. Exiting...${NC}"
