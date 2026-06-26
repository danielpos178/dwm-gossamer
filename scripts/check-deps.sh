#!/bin/bash
# dwm-titus dependency checker — supports Arch (pacman) and Void (xbps)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

MISSING=0

detect_pkg_manager() {
    if command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v xbps-install &>/dev/null; then
        echo "xbps"
    else
        echo "unknown"
    fi
}

PKG_MGR=$(detect_pkg_manager)

check_cmd() {
    if command -v "$1" &>/dev/null; then
        printf "  ${GREEN}✓${NC} %s\n" "$1"
    else
        printf "  ${RED}✗${NC} %s ${YELLOW}(missing)${NC}\n" "$1"
        MISSING=$((MISSING + 1))
    fi
}

check_pkg_pacman() {
    if pacman -Qi "$1" &>/dev/null; then
        printf "  ${GREEN}✓${NC} %s\n" "$1"
    else
        printf "  ${RED}✗${NC} %s ${YELLOW}(not installed)${NC}\n" "$1"
        MISSING=$((MISSING + 1))
    fi
}

check_pkg_xbps() {
    if xbps-query -l 2>/dev/null | command grep -q "^ii $1 "; then
        printf "  ${GREEN}✓${NC} %s\n" "$1"
    else
        printf "  ${RED}✗${NC} %s ${YELLOW}(not installed)${NC}\n" "$1"
        MISSING=$((MISSING + 1))
    fi
}

check_pkg() {
    case "$PKG_MGR" in
        pacman) check_pkg_pacman "$1" ;;
        xbps)   check_pkg_xbps "$1" ;;
        *)      printf "  ${YELLOW}?${NC} %s (cannot check — unknown pkg manager)\n" "$1" ;;
    esac
}

check_font() {
    local label="$1"
    shift

    if [ "$#" -eq 0 ]; then
        set -- "$label"
    fi

    local pattern
    for pattern in "$@"; do
        if fc-list 2>/dev/null | command grep -qi "$pattern"; then
            printf "  ${GREEN}✓${NC} %s\n" "$label"
            return
        fi
    done

    printf "  ${RED}✗${NC} %s ${YELLOW}(not found)${NC}\n" "$label"
    MISSING=$((MISSING + 1))
}

check_font_any() {
    local label="$1"
    shift
    check_font "$label" "$@"
}

echo ""
echo "═══ dwm-titus Dependency Check ($PKG_MGR) ═══"
echo ""

echo "Build Dependencies (required to compile):"
case "$PKG_MGR" in
    pacman)
        for pkg in base-devel libx11 libxft libxinerama imlib2 libxcb xcb-util freetype2 fontconfig; do
            check_pkg "$pkg"
        done
        ;;
    xbps)
        for pkg in base-devel libX11-devel libxft-devel libXinerama-devel imlib2-devel libxcb-devel xcb-util-devel freetype-devel fontconfig-devel; do
            check_pkg "$pkg"
        done
        ;;
esac
check_cmd "cc"
check_cmd "make"
echo ""

echo "X Server Components:"
case "$PKG_MGR" in
    pacman)
        if pacman -Qq 2>/dev/null | grep -q '^xlibre'; then
            xlibre_pkg=$(pacman -Qq 2>/dev/null | grep '^xlibre' | head -1)
            printf "  ${GREEN}✓${NC} Xlibre detected (%s)\n" "$xlibre_pkg"
        elif pacman -Qi xorg-server &>/dev/null; then
            printf "  ${GREEN}✓${NC} xorg-server\n"
        else
            printf "  ${RED}✗${NC} xorg-server or xlibre ${YELLOW}(not installed)${NC}\n"
            MISSING=$((MISSING + 1))
        fi
        for pkg in xorg-xinit xorg-xrandr xorg-xset xorg-xsetroot; do
            check_pkg "$pkg"
        done
        ;;
    xbps)
        check_pkg xorg-server
        for pkg in xinit xrandr xsetroot xset; do
            check_pkg "$pkg"
        done
        ;;
esac

echo "Runtime Dependencies (desktop experience):"
check_cmd "rofi"
check_cmd "picom"
check_cmd "dunst"
check_cmd "feh"
check_cmd "flameshot"
check_cmd "dex"
check_cmd "amixer"
echo ""

echo "Audio Stack:"
check_cmd "pipewire"
check_cmd "wpctl"
check_cmd "wireplumber"
check_cmd "pavucontrol"
echo ""

echo "Terminal Emulators (at least one required):"
TERM_FOUND=0
for term in alacritty kitty st; do
    if command -v "$term" &>/dev/null; then
        printf "  ${GREEN}✓${NC} %s\n" "$term"
        TERM_FOUND=1
    fi
done
if [ $TERM_FOUND -eq 0 ]; then
    printf "  ${RED}✗${NC} No supported terminal found ${YELLOW}(install alacritty, kitty, or st)${NC}\n"
    MISSING=$((MISSING + 1))
fi
echo ""

echo "Optional (recommended):"
check_cmd "polybar"
check_cmd "xdg-open"
echo ""

echo "Fonts:"
check_font_any "MesloLGS Nerd Font (NF compatible)" "MesloLGS Nerd Font" "MesloLGS Nerd Font Mono" "MesloLGS NF"
check_font "Noto Color Emoji"
echo ""

echo "Session Setup:"
if [ -f "$HOME/.xinitrc" ]; then
    printf "  ${GREEN}✓${NC} ~/.xinitrc exists\n"
else
    printf "  ${YELLOW}○${NC} ~/.xinitrc not found (needed for startx)\n"
fi
echo ""

if [ $MISSING -eq 0 ]; then
    printf "${GREEN}All dependencies satisfied. Ready to build!${NC}\n"
    echo "  Run: make && sudo make install"
    exit 0
else
    printf "${RED}$MISSING missing dependency/dependencies.${NC}\n"
    case "$PKG_MGR" in
        pacman) echo "  Install missing packages with: sudo pacman -S <package>" ;;
        xbps)   echo "  Install missing packages with: sudo xbps-install -S <package>" ;;
        *)      echo "  Install missing packages using your system package manager." ;;
    esac
    echo "  Or run: ./install.sh   (automated install)"
    exit 1
fi
echo ""
