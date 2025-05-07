#!/usr/bin/env sh
# Run emacs daemon as emacsuser
cd /w
exec /sbin/setuser emacsuser /usr/local/bin/emacs --fg-daemon
