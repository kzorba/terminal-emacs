#!/usr/bin/env sh
#
# Adjustments of the container to the environment during boot
#

# Fix docker socket ownership
if [ -S "var/run/docker.sock" ]; then
    chgrp docker /var/run/docker.sock
fi

if [ -d "$WORKDIR/org" ]; then
    echo "Found org directory in $WORKDIR, creating symbolic link for emacs"
    ln -s $WORKDIR/org /h/${USERNAME}/org
    chown -h ${USERNAME}:${USERNAME} /h/${USERNAME}/org
fi

# direnv config
# we trust all .envrc files under the exposed host directory
mkdir -p /h/${USERNAME}/.config/direnv
cat <<EOF >/h/${USERNAME}/.config/direnv/direnv.toml
[whitelist]
prefix = [ "$WORKDIR" ]
EOF
chown -R ${USERNAME}:${USERNAME} /h/${USERNAME}/.config/direnv
