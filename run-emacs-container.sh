#!/usr/bin/env sh

export WORKDIR="/v"
# Start docker daemon before this.
docker run -d --rm --name devcon \
  --hostname devcon \
  -e EMACS_UID=$(id -u) \
  -e EMACS_GID=$(id -g) \
  -e WORKDIR=$WORKDIR \
  -v "$HOME":"$WORKDIR" \
  -p 2222:22 \
  kzorba/terminal-emacs
