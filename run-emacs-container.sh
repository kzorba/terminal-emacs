#!/usr/bin/env sh

export WORKDIR="/v"
# Start docker daemon before this.
docker run -d --rm --name terminal-emacs \
  -e EMACS_UID=$(id -u) \
  -e EMACS_GID=$(id -g) \
  -e WORKDIR=$WORKDIR \
  -v "$HOME":"$WORKDIR"
  kzorba/terminal-emacs
