#!/usr/bin/env sh

export WORKDIR="/w"
# Start docker daemon before this.
docker run -d --rm --name terminal-emacs \
  -e EMACS_UID=$(id -u) \
  -e EMACS_GID=$(id -g) \
  -e WORKDIR=$WORKDIR \
  -v "$HOME":"$WORKDIR" \
  ghcr.io/kzorba/terminal-emacs
