#!/usr/bin/env sh
# Run emacs daemon as emacsuser in the container
cd $WORKDIR
exec /sbin/setuser ${USERNAME} /usr/local/bin/emacs --fg-daemon
