#!/bin/bash
# .xinitrc — invoked by startx to launch dwm
# elogind provides XDG_RUNTIME_DIR and XDG_SESSION_TYPE on login;
# the fallbacks below handle edge cases (autologin, direct TTY startx).

# Source user profile so PATH includes ~/.local/bin, /usr/local/bin, etc.
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"

# Ensure X session variables are set (elogind provides these on normal TTY login)
export XDG_SESSION_TYPE=x11
[ -z "$XDG_RUNTIME_DIR" ] && export XDG_RUNTIME_DIR="/run/user/$(id -u)"

exec dbus-run-session dwm
