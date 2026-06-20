#!/bin/bash
# .xinitrc — only used when starting dwm via startx (not SDDM)
# All setup (DPMS, dbus env, services) is handled by autostart.sh

# Source user profile so PATH includes ~/.local/bin, /usr/local/bin, etc.
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"

exec dbus-run-session dwm
