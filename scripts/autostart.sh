#!/bin/sh
# dwm-titus autostart — single unified autostart script

# Disable DPMS and screen blanking (prevents GPU/display wake issues)
xset s off
xset s noblank
xset -dpms

# Export display env to session manager/dbus in parallel (both are IPC round-trips)
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user import-environment DISPLAY XAUTHORITY &
fi

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    if command -v systemctl >/dev/null 2>&1; then
        dbus-update-activation-environment --systemd DISPLAY XAUTHORITY 2>/dev/null &
    else
        dbus-update-activation-environment DISPLAY XAUTHORITY 2>/dev/null &
    fi
fi
wait

# Source theme environment so tray apps inherit QT_QPA_PLATFORMTHEME and GTK_THEME
THEME_ENV="${XDG_CONFIG_HOME:-$HOME/.config}/dwm-titus/theme-env.sh"
if [ -f "$THEME_ENV" ]; then
    . "$THEME_ENV"
    if command -v dbus-update-activation-environment >/dev/null 2>&1; then
        dbus-update-activation-environment QT_QPA_PLATFORMTHEME GTK_THEME 2>/dev/null || true
    fi
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user import-environment QT_QPA_PLATFORMTHEME GTK_THEME 2>/dev/null || true
    fi
fi

feh --randomize --bg-fill ~/Pictures/backgrounds/* 2>/dev/null &
picom -b 2>/dev/null &
dunst 2>/dev/null &

# Clipboard manager daemon (passive X11 selection monitor)
if command -v clipmenud &>/dev/null; then
    clipmenud 2>/dev/null &
fi

# PipeWire audio (needed on non-systemd systems; harmless on systemd if already running)
if command -v pipewire &>/dev/null && ! pgrep -x pipewire &>/dev/null; then
    pipewire 2>/dev/null &
    sleep 0.5
    if command -v wireplumber &>/dev/null; then
        wireplumber 2>/dev/null &
    elif command -v pipewire-media-session &>/dev/null; then
        pipewire-media-session 2>/dev/null &
    fi
    if command -v pipewire-pulse &>/dev/null; then
        pipewire-pulse 2>/dev/null &
    fi
    # Wait for PulseAudio socket so polybar's internal/pulseaudio module works
    PA_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pulse/native"
    i=0
    while [ ! -S "$PA_SOCK" ] && [ "$i" -lt 30 ]; do
        sleep 0.2
        i=$((i + 1))
    done
fi

for agent in \
    /usr/libexec/polkit-mate-authentication-agent-1 \
    /usr/lib/mate-polkit/polkit-mate-authentication-agent-1 \
    /usr/libexec/polkit-gnome-authentication-agent-1 \
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
    /usr/libexec/polkit-kde-authentication-agent-1 \
    /usr/lib/polkit-kde/polkit-kde-authentication-agent-1 \
    /usr/bin/xfce-polkit \
    /usr/bin/lxpolkit \
    /usr/lib/lxpolkit/lxpolkit; do
    if [ -x "$agent" ]; then
        "$agent" &
        break
    fi
done

"$HOME/.config/polybar/launch.sh" 2>/dev/null &

# Initialize keyboard layout (always starts with default)
if command -v dwm-kblayout >/dev/null 2>&1; then
    dwm-kblayout get >/dev/null 2>&1 || setxkbmap -layout us
fi

dex -a 2>/dev/null
