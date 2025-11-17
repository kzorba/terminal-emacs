#!/usr/bin/env sh

export WORKDIR=$HOME
# Start docker daemon before this.
docker run -d --rm --name devcon \
  --hostname devcon \
  -e EMACS_UID=$(id -u) \
  -e EMACS_GID=$(id -g) \
  -e WORKDIR=$WORKDIR \
  -v "$HOME":"$WORKDIR" \
  -v devcon_cache_volume:/home/emacsuser/.cache \
  -v devcon_share_volume:/home/emacsuser/.local/share \
  -p 2222:22 \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  kzorba/terminal-emacs
