#!/usr/bin/env sh

# Start docker daemon before this.
docker run -d --rm --name ghcr.io/kzorba/terminal-emacs \
  -e EMACS_UID=$(id -u) \
  -e EMACS_GID=$(id -g) \
  -v "$HOME":/w \
  kzorba/terminal-emacs
