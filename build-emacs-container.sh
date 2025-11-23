#!/usr/bin/env sh

# Build with your UID/GID and DOCKER_GID
docker build \
    --build-arg USER_UID=$(id -u) \
    --build-arg USER_GID=$(id -g) \
    --build-arg DOCKER_GID=$(ls -Ln /var/run/docker.sock 2>/dev/null | awk '{print $4}' || echo $(id -g)) \
    -t ${USER}/terminal-emacs .
