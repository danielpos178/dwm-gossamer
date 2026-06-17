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

mkdir -p "$HOME/Pictures"
if [ ! -d "$BG_DIR" ]; then
    info "Downloading Nord wallpapers..."
    git clone https://github.com/ChrisTitusTech/nord-background.git "$BG_DIR" 2>/dev/null \
        && ok "Wallpapers downloaded to $BG_DIR" \
        || warn "Failed to download wallpapers. Add your own to $BG_DIR."
else
    ok "Wallpapers already present."
fi

# ── Display manager ──────────────────────────────────────
currentdm=""
for dm in lightdm sddm gdm; do command -v "$dm" &>/dev/null && { currentdm="$dm"; break; }; done

if [ -n "$currentdm" ]; then
    ok "Display manager already installed: $currentdm"
else
    info "No display manager found — installing LightDM..."
    for pkg in "${DM_PKGS[@]}"; do
        install_packages "$pkg" 2>/dev/null \
            || warn "Package '$pkg' not found — skipping."
    done
    enable_service "$DM_SERVICE"
    ok "LightDM installed and enabled."
fi

# ── LightDM greeter config ───────────────────────────────
if command -v lightdm &>/dev/null; then
    info "Deploying LightDM GTK greeter config..."
    sudo make -C "$REPO_DIR/lightdm" install
    ok "LightDM config deployed."
fi

# ── Build & Install ──────────────────────────────────────
cd "$REPO_DIR"
sudo make clean install

# ── Done ─────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║          Installation Complete!           ║"
echo "╚═══════════════════════════════════════════╝"
echo ""
info "Detected: $DISTRO_NAME"
echo "  • Edit config.h to customize, then: make && sudo make install"
echo "  • Log out and select 'dwm', or start with: startx"
echo ""
echo "  SUPER+/   keybind viewer     SUPER+X  terminal"
echo "  SUPER+F1  control center     SUPER+R  app launcher (rofi)"
echo "  SUPER+Q   close window"
echo ""
echo "  Full reference: docs/src/keybinds.md or SUPER+/ in dwm"
echo ""
