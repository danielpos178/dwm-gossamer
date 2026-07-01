#!/bin/bash
# .xinitrc — invoked by startx to launch dwm
# elogind provides XDG_RUNTIME_DIR and XDG_SESSION_TYPE on login;
# the fallbacks below handle edge cases (autologin, direct TTY startx).

# Source user profile so PATH includes ~/.local/bin, /usr/local/bin, etc.
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"

# Source theme environment
THEME_ENV="${XDG_CONFIG_HOME:-$HOME/.config}/dwm-titus/theme-env.sh"
[ -f "$THEME_ENV" ] && . "$THEME_ENV"

# Ensure X session environment variables are set
export XDG_SESSION_TYPE=x11
[ -z "$XDG_RUNTIME_DIR" ] && export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# Kill orphaned background processes when the session ends.
cleanup() {
    for p in clipmenud; do
        pkill -x "$p" 2>/dev/null || true
    done
}
trap cleanup EXIT

dbus-run-session dwm
