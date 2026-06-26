#!/bin/bash
# ─────────────────────────────────────────────────────────
# install.sh — dwm-titus installer (x86_64)
# Supports: Arch Linux, Void Linux
# Distro-specific logic lives in scripts/distros/*.sh
# ─────────────────────────────────────────────────────────
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$REPO_DIR/scripts/dwm-utils.sh"

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' CYAN='\033[0;36m' NC='\033[0m'
info() { printf "${CYAN}[INFO]${NC} %s\n" "$1"; }
ok()   { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
err()  { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

# ── Detect and load distro profile ───────────────────────
load_distro
setup_pkg_manager

BG_DIR="$HOME/Pictures/backgrounds"

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║        dwm-titus Installer               ║"
echo "╚═══════════════════════════════════════════╝"
echo ""
info "Detected: $DISTRO_NAME"
info "Package manager: $PKG_CMD"

# ── Build dependencies ───────────────────────────────────
info "Installing build dependencies..."
install_packages "${BUILD_DEPS[@]}"

if has_xlibre; then
    info "Xlibre detected — skipping xorg-server."
else
    install_packages "${XORG_PKGS[@]}"
fi
ok "Build dependencies installed."

# ── Runtime dependencies ─────────────────────────────────
info "Installing runtime dependencies..."
for pkg in "${RUNTIME_DEPS[@]}"; do
    install_packages "$pkg" 2>/dev/null \
        || warn "Package '$pkg' not found — skipping."
done
ok "Runtime dependencies installed."

# ── PipeWire audio ────────────────────────────────────────
info "Setting up PipeWire audio..."
if command -v pipewire &>/dev/null; then
    if command -v systemctl &>/dev/null; then
        # systemd: enable PipeWire user services for the login user
        TARGET_USER="${SUDO_USER:-$USER}"
        if [ "$TARGET_USER" != "root" ]; then
            sudo loginctl enable-linger "$TARGET_USER" 2>/dev/null || true
            for svc in pipewire pipewire-pulse wireplumber; do
                sudo -u "$TARGET_USER" systemctl --user enable "${svc}.service" 2>/dev/null \
                    || true
            done
            ok "PipeWire user services enabled for $TARGET_USER."
        else
            warn "Running as root — enable PipeWire user services manually for your user."
        fi
    else
        # runit (Void Linux): PipeWire has no system-level runit services.
        # It is started as the current user by autostart.sh on each login.
        ok "PipeWire installed — will be started by autostart.sh on login."
    fi
else
    warn "PipeWire not found — audio may not work."
fi

# ── Qt / GTK theming ─────────────────────────────────────
info "Installing Qt/GTK dark-mode dependencies..."
# dconf: required for gsettings to persist GTK color-scheme changes
# qt6ct / qt5ct: QT_QPA_PLATFORMTHEME backend for Qt dark mode
install_packages "${THEME_DEPS[0]}" 2>/dev/null \
    || warn "Package '${THEME_DEPS[0]}' not found — skipping."
install_packages "${THEME_DEPS[1]}" 2>/dev/null \
    || install_packages "${THEME_DEPS[2]}" 2>/dev/null \
    || warn "Neither qt6ct nor qt5ct found — Qt apps may not respect dark mode."
ok "Qt/GTK theming dependencies installed."

# ── Fonts ────────────────────────────────────────────────
info "Installing fonts..."
for pkg in "${FONT_PKGS[@]}"; do
    install_packages "$pkg" 2>/dev/null \
        || warn "Font package '$pkg' not found — skipping."
done
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if [ -d "$REPO_DIR/config/polybar/fonts" ]; then
    cp -r "$REPO_DIR/config/polybar/fonts/"* "$FONT_DIR/"
    fc-cache -fv >/dev/null 2>&1
fi
ok "Fonts installed."

# ── GTK Theme (Gruvbox) ──────────────────────────────────
info "Installing Gruvbox GTK theme..."
GTK_THEME_DIR="$HOME/.themes/Gruvbox-Dark-Hard"
if [ ! -d "$GTK_THEME_DIR" ]; then
    mkdir -p "$HOME/.themes"
    if command -v git &>/dev/null; then
        git clone --depth 1 https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git /tmp/gruvbox-gtk 2>/dev/null \
            && cp -r /tmp/gruvbox-gtk/themes/Gruvbox-Dark-Hard "$GTK_THEME_DIR" 2>/dev/null \
            && ok "Gruvbox GTK theme installed." \
            || warn "Failed to install Gruvbox GTK theme."
        rm -rf /tmp/gruvbox-gtk 2>/dev/null
    else
        warn "git not found — install Gruvbox GTK theme manually."
    fi
else
    ok "Gruvbox GTK theme already installed."
fi

# ── Terminal emulator ────────────────────────────────────
terminal=""
for t in alacritty kitty; do command -v "$t" &>/dev/null && { terminal="$t"; break; }; done

if [ -n "$terminal" ]; then
    ok "Terminal already installed: $terminal"
else
    info "No supported terminal found — installing $TERMINAL_PKG..."
    install_packages "$TERMINAL_PKG" 2>/dev/null \
        || warn "$TERMINAL_PKG not found — install your preferred terminal manually."
fi

# ── Polybar + XDG dirs + wallpapers ──────────────────────
install_packages "$BAR_PKG" 2>/dev/null || warn "$BAR_PKG not found."
command -v xdg-user-dirs-update &>/dev/null && xdg-user-dirs-update

mkdir -p "$BG_DIR"
if [ -z "$(ls -A "$BG_DIR" 2>/dev/null)" ]; then
    info "Copying default wallpaper..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/config/background.jpg" ]; then
        cp "$SCRIPT_DIR/config/background.jpg" "$BG_DIR/wallpaper.jpg" 2>/dev/null \
            && ok "Default wallpaper copied to $BG_DIR" \
            || warn "Failed to copy wallpaper. Add your own to $BG_DIR."
    else
        warn "No default wallpaper found. Add your own to $BG_DIR."
    fi
else
    ok "Wallpapers already present."
fi

# ── Essential system services (runit/Void Linux) ──────────
# Enables dbus, elogind, and NetworkManager. On runit, elogind provides
# session/seat management, XDG_RUNTIME_DIR, and power event handling.
# On systemd (Arch), systemd-logind handles this natively — nothing to enable.
if ! command -v systemctl &>/dev/null; then
    enable_essential_services
fi

# ── Build & Install ──────────────────────────────────────
cd "$REPO_DIR"
sudo make clean install

# ── Apply theme (GTK/Qt/polybar/terminal) ────────────────
info "Applying theme to GTK and Qt..."
TARGET_USER="${SUDO_USER:-$USER}"
if [ "$TARGET_USER" != "root" ]; then
    THEME_APPLY="$REPO_DIR/scripts/theme-apply.sh"
    if [ -x "$THEME_APPLY" ]; then
        sudo -u "$TARGET_USER" "$THEME_APPLY" 2>/dev/null \
            && ok "Theme applied — GTK/Qt apps will use dark mode." \
            || warn "theme-apply.sh failed — you may need to run it manually."
    else
        warn "theme-apply.sh not found — run it manually to apply GTK/Qt theme."
    fi
else
    warn "Running as root — run theme-apply.sh as your user to apply GTK/Qt theme."
fi

# ── Done ─────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║          Installation Complete!           ║"
echo "╚═══════════════════════════════════════════╝"
echo ""
info "Detected: $DISTRO_NAME"
echo "  • Edit config.h to customize, then: make && sudo make install"
echo "  • Start dwm manually with: startx"
echo ""
echo "  SUPER+/   keybind viewer     SUPER+X  terminal"
echo "  SUPER+F1  control center     SUPER+R  app launcher (rofi)"
echo "  SUPER+Q   close window"
echo ""
echo "  Full reference: docs/src/keybinds.md or SUPER+/ in dwm"
echo ""
