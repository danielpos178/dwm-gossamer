#!/bin/bash
# .xinitrc — only used when starting dwm via startx (not SDDM)
# All setup (DPMS, dbus env, services) is handled by autostart.sh

# Source user profile so PATH includes ~/.local/bin, /usr/local/bin, etc.
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"

# Required for terminal emulators (alacritty, kitty, ghostty) on Void Linux / seatd.
# Without these, they cannot access /dev/tty and silently fail to open.
export XDG_SESSION_TYPE=x11
[ -z "$XDG_RUNTIME_DIR" ] && export XDG_RUNTIME_DIR="/run/user/$(id -u)"

exec dbus-run-session dwm
