#!/usr/bin/env sh
#
# Adjustments of the container to the environment during boot
#

# Create symlinks
if [ -d "$WORKDIR/org" ]; then
    echo "Found org directory in $WORKDIR, creating symbolic link for emacs"
    ln -s $WORKDIR/org /home/emacsuser/org
    chown -h emacsuser:emacsuser /home/emacsuser/org
fi

# direnv config
# we trust all .envrc files under the exposed host directory
mkdir -p /home/emacsuser/.config/direnv
cat <<EOF >/home/emacsuser/.config/direnv/direnv.toml
[whitelist]
prefix = [ "$WORKDIR" ]
EOF
chown -R emacsuser:emacsuser /home/emacsuser/.config/direnv

# fix .cache permissions
if [ -d /home/emacsuser/.cache ]; then
    chown -R emacsuser:emacsuser /home/emacsuser/.cache
fi

#
# If EMACS_UID and EMACS_GID are passed in the environment
# fix emacsuser according to them.
# We do this to match the uid, gid of the container user
# on the host.
#

# Check if EMACS_UID is set and not empty
if [ -n "$EMACS_UID" ]; then
    echo "EMACS_UID is set to $EMACS_UID"

    # Get current UID of emacsuser
    CURRENT_UID=$(id -u emacsuser)

    # Only change if it's different
    if [ "$CURRENT_UID" -ne "$EMACS_UID" ]; then
        echo "Changing UID of emacsuser from $CURRENT_UID to $EMACS_UID..."
        # Modify the UID
        usermod -u "$EMACS_UID" emacsuser
        # chown files in emacsuser home directory.
        # usermod above should handle that
        # chown -R "$EMACS_UID" /home/emacsuser
        echo "UID updated successfully."
    else
        echo "emacsuser already has UID $EMACS_UID. No change needed."
    fi
else
    echo "EMACS_UID is not set. Skipping UID change."
fi

# Update GID if EMACS_GID is set
if [ -n "$EMACS_GID" ]; then
    echo "EMACS_GID is set to $EMACS_GID"

    CURRENT_GID=$(id -g emacsuser)
    GROUP_NAME=$(id -gn emacsuser)

    if [ "$CURRENT_GID" -ne "$EMACS_GID" ]; then
        echo "Changing GID of group '$GROUP_NAME' from $CURRENT_GID to $EMACS_GID..."
        groupmod -o -g "$EMACS_GID" "$GROUP_NAME"
        # chgrp in emacsuser home directory, to fix the old gid
        chgrp -R "$GROUP_NAME" /home/emacsuser
        echo "GID updated successfully."
    else
        echo "Group $GROUP_NAME already has GID $EMACS_GID. No change needed."
    fi
else
    echo "EMACS_GID is not set. Skipping GID change."
fi
