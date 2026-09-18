#!/usr/bin/env sh

# The images to build.
# ---
# orgman: daily organization
# snake: Python development
# rusty: Rust development
# lambda: Emacs lisp / scheme development
# knr: C development
# ---
# Adjust the list accordingly.

export IMAGES="orgman snake rusty lambda knr"

# Build with your UID/GID and DOCKER_GID
for i in $IMAGES; do
    echo "===>"
    echo "===> Building $i"
    echo "===>"
    docker build --progress=plain \
        --build-arg USER_UID=$(id -u) \
        --build-arg USER_GID=$(id -g) \
        --build-arg DOCKER_GID=$(ls -Ln /var/run/docker.sock 2>/dev/null | awk '{print $4}' || echo $(id -g)) \
        -f Dockerfile.$i \
        -t ${USER}/terminal-emacs-$i .
done
