#!/bin/bash
# dwm-utils.sh — Shared utility library for dwm-titus

detect_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

load_distro() {
    local os_id
    os_id="$(detect_distro)"
    local distro_file="${REPO_DIR}/scripts/distros/${os_id}.sh"

    if [ ! -f "$distro_file" ]; then
        echo "[ERROR] Unsupported distribution: $os_id" >&2
        echo "[ERROR] Supported: arch, void" >&2
        exit 1
    fi

    # shellcheck disable=SC1090
    source "$distro_file"
}

# Detect GPU type: nvidia, amd, intel, or unknown
detect_gpu() {
    if command -v lspci &>/dev/null; then
        local vga
        vga=$(lspci 2>/dev/null | command grep -i 'vga\|3d\|display' || true)
        if echo "$vga" | command grep -qi nvidia; then
            echo "nvidia"
        elif echo "$vga" | command grep -qi 'amd\|radeon'; then
            echo "amd"
        elif echo "$vga" | command grep -qi intel; then
            echo "intel"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# Detect battery device name (e.g., BAT0, BAT1)
detect_battery() {
    command ls /sys/class/power_supply/ 2>/dev/null | command grep -E '^BAT[0-9]' | head -1
}

# Detect AC adapter name (e.g., ACAD, AC0, ADP1)
detect_adapter() {
    command ls /sys/class/power_supply/ 2>/dev/null | command grep -Ev '^BAT' | head -1
}

# Detect if running on a laptop (has battery)
is_laptop() {
    [ -n "$(detect_battery)" ]
}

# Detect first available terminal emulator
detect_terminal() {
    for t in alacritty kitty st xterm; do
        if command -v "$t" &>/dev/null; then
            echo "$t"
            return
        fi
    done
    echo "xterm"
}
