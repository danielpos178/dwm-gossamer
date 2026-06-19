#!/bin/bash
# ─────────────────────────────────────────────────────────
# void.sh — Void Linux distro profile for dwm-titus
# Sourced by install.sh / install-arm.sh after OS detection.
# Provides: package lists, install_packages(), enable_service()
#
# Notes:
#   - Uses xbps instead of pacman
#   - Service management uses runit (symlinks in /var/service)
#   - Build deps use -devel suffix (not freetype2, not libx11)
#   - Some packages have different names (Thunar, NetworkManager)
#   - Uses nerd-fonts-ttf instead of ttf-meslo-nerd (not packaged on Void)
# ─────────────────────────────────────────────────────────

DISTRO_NAME="Void Linux"

# ── Package Manager ──────────────────────────────────────
setup_pkg_manager() {
    # Sync repos before installing anything
    sudo xbps-install -Sy >/dev/null 2>&1

    # Enable nonfree repository (required for flameshot and others)
    if [ ! -f /usr/share/xbps.d/10-repository-nonfree.conf ]; then
        echo "[INFO] Enabling nonfree repository..."
        sudo xbps-install -Sy --yes void-repo-nonfree >/dev/null 2>&1
        sudo xbps-install -Sy >/dev/null 2>&1
    fi
}

install_packages() {
    sudo xbps-install -Sy --yes "$@" >/dev/null
}

# ── Service Management (runit) ───────────────────────────
enable_service() {
    local svc="$1"
    if [ -d "/etc/sv/$svc" ] && [ ! -L "/var/service/$svc" ]; then
        sudo ln -s "/etc/sv/$svc" "/var/service/$svc"
    fi
}

disable_service() {
    local svc="$1"
    if [ -L "/var/service/$svc" ]; then
        sudo rm "/var/service/$svc"
    fi
}

BUILD_DEPS=(
    base-devel libX11-devel libXft-devel libXinerama-devel libXrender-devel
    imlib2-devel libxcb-devel xcb-util-devel freetype-devel fontconfig-devel
)

XORG_PKGS=(
    xorg-server xinit xrandr xsetroot xset xauth
    xf86-input-libinput libinput
)

RUNTIME_DEPS=(
    rofi picom dunst feh flameshot dex mate-polkit elogind alsa-utils
    git unzip xclip xprop Thunar gvfs tumbler arandr
    thunar-archive-plugin nwg-look xdg-user-dirs
    xdg-desktop-portal-gtk pipewire wireplumber pipewire-pulse pavucontrol gnome-keyring
    NetworkManager network-manager-applet libnotify rsync
)

THEME_DEPS=(dconf qt6ct qt5ct)
FONT_PKGS=(
    noto-fonts-ttf            # Google Noto: sans, serif, mono (multilingual)
    noto-fonts-cjk            # Chinese, Japanese, Korean
    noto-fonts-emoji           # Emoji support
    dejavu-fonts-ttf           # DejaVu: common baseline font family
    liberation-fonts-ttf       # Liberation: metric-compatible with MS fonts
    font-awesome               # Font Awesome icons (polybar/dwm)
    nerd-fonts-ttf             # Nerd Fonts: icons for terminal/polybar
)
TERMINAL_PKG=alacritty
BAR_PKG=polybar
DM_PKGS=(lightdm lightdm-slick-greeter)
DM_SERVICE=lightdm

# ── Distro-Specific Helpers ──────────────────────────────

# Xlibre is not expected on Void Linux
has_xlibre() {
    false
}
