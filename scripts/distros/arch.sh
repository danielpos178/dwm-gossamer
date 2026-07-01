#!/bin/bash
# arch.sh — Arch Linux distro profile for dwm-titus

DISTRO_NAME="Arch Linux"

# Prefer AUR helpers for access to AUR packages
setup_pkg_manager() {
    if command -v paru &>/dev/null; then
        PKG_CMD="paru -S --needed --noconfirm"
    elif command -v yay &>/dev/null; then
        PKG_CMD="yay -S --needed --noconfirm"
    else
        PKG_CMD="sudo pacman -S --needed --noconfirm"
    fi
}

install_packages() {
    # shellcheck disable=SC2086
    $PKG_CMD "$@" >/dev/null
}

enable_service() {
    sudo systemctl enable "$1"
}

disable_service() {
    sudo systemctl disable "$1"
}

BUILD_DEPS=(
    base-devel libx11 libxft libxinerama libxrender imlib2
    libxcb xcb-util freetype2 fontconfig
)

XORG_PKGS=(
    xorg-server xorg-xinit xorg-xrandr xorg-xsetroot xorg-xset
)

RUNTIME_DEPS=(
    rofi picom dunst feh flameshot dex mate-polkit polkit alsa-utils
    git unzip xclip xorg-xprop thunar gvfs tumbler dbus mesa libglvnd
    thunar-archive-plugin nwg-look xdg-user-dirs xorg-xkb-utils xdg-utils
    xdg-desktop-portal-gtk pipewire wireplumber pipewire-pulse pipewire-alsa pavucontrol gnome-keyring
    networkmanager network-manager-applet libnotify rsync
    clipmenu clipnotify xsel
)

THEME_DEPS=(dconf qt6ct qt5ct)
FONT_PKGS=(noto-fonts-emoji ttf-meslo-nerd)
TERMINAL_PKG=alacritty
BAR_PKG=polybar

# Check if Xlibre is installed (skip xorg-server if so)
has_xlibre() {
    pacman -Qq 2>/dev/null | grep -q '^xlibre'
}
