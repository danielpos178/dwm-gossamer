#!/bin/bash
# void.sh — Void Linux distro profile for dwm-gossamer

DISTRO_NAME="Void Linux"

PKG_CMD="sudo xbps-install --yes"

setup_pkg_manager() {
    sudo xbps-install -Sy >/dev/null 2>&1

    # Enable nonfree repository
    if [ ! -f /usr/share/xbps.d/10-repository-nonfree.conf ]; then
        echo "[INFO] Enabling nonfree repository..."
        sudo xbps-install -Sy --yes void-repo-nonfree >/dev/null 2>&1
        sudo xbps-install -Sy >/dev/null 2>&1
    fi
}

install_packages() {
    sudo xbps-install --yes "$@" >/dev/null
}

enable_service() {
    local svc="$1"
    if [ ! -d "/etc/sv/$svc" ]; then
        return 1
    fi
    if [ -L "/var/service/$svc" ]; then
        return 0
    fi
    sudo ln -s "/etc/sv/$svc" "/var/service/$svc"
}

disable_service() {
    local svc="$1"
    if [ -L "/var/service/$svc" ]; then
        sudo rm "/var/service/$svc"
    fi
}

enable_essential_services() {
    info "Enabling essential runit services..."
    for svc in dbus elogind polkitd NetworkManager; do
        if enable_service "$svc"; then
            ok "$svc enabled."
        else
            warn "$svc service directory not found — skipping."
        fi
    done
}

BUILD_DEPS=(
    base-devel libX11-devel libXft-devel libXinerama-devel libXrender-devel
    imlib2-devel libxcb-devel xcb-util-devel freetype-devel fontconfig-devel
)

XORG_PKGS=(
    xorg-server xinit xrandr xsetroot xset xauth
    xf86-input-libinput libinput
)

# elogind provides session/seat management, XDG_RUNTIME_DIR, and power event handling
RUNTIME_DEPS=(
    rofi picom dunst feh flameshot dex mate-polkit polkit elogind alsa-utils dbus
    mesa-dri mesa git unzip xclip xprop Thunar gvfs tumbler arandr
    thunar-archive-plugin nwg-look xdg-user-dirs xkbutils
    xdg-desktop-portal-gtk pipewire wireplumber pavucontrol gnome-keyring
    NetworkManager network-manager-applet libnotify rsync
    clipmenu clipnotify xsel
)

THEME_DEPS=(dconf qt6ct qt5ct)
FONT_PKGS=(
    noto-fonts-ttf            # Google Noto: sans, serif, mono (multilingual)
    noto-fonts-cjk            # Chinese, Japanese, Korean
    noto-fonts-emoji           # Emoji support
    dejavu-fonts-ttf           # DejaVu: common baseline font family
    liberation-fonts-ttf       # Liberation: metric-compatible with MS fonts
    font-awesome6              # Font Awesome 6 icons (polybar/dwm)
    nerd-fonts-ttf             # Nerd Fonts: icons for terminal/polybar
)
TERMINAL_PKG=alacritty
BAR_PKG=polybar

# Xlibre is not expected on Void Linux
has_xlibre() {
    false
}
