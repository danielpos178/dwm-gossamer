#!/usr/bin/env bash
# kblayout.sh — polybar helper for keyboard layout display
#
# Wraps dwm-kblayout for polybar consumption.
# Handles label formatting and scroll events.
#
# Usage (polybar custom/script):
#   exec = kblayout.sh --polybar
#   scroll-up = kblayout.sh --scroll-up
#   scroll-down = kblayout.sh --scroll-down

set -euo pipefail

# Locate dwm-kblayout: check PATH, then config dir, then dev repo
KBLAYOUT=""
if command -v dwm-kblayout >/dev/null 2>&1; then
    KBLAYOUT="dwm-kblayout"
elif [[ -x "${XDG_CONFIG_HOME:-$HOME/.config}/dwm-titus/dwm-kblayout" ]]; then
    KBLAYOUT="${XDG_CONFIG_HOME:-$HOME/.config}/dwm-titus/dwm-kblayout"
elif [[ -x "${HOME}/.local/share/dwm-titus/scripts/dwm-kblayout" ]]; then
    KBLAYOUT="${HOME}/.local/share/dwm-titus/scripts/dwm-kblayout"
else
    printf '??' && exit 0
fi

# Layout display names (abbreviated for bar)
declare -A LABELS=(
    [us]="EN"
    [ro]="RO"
    [de]="DE"
    [fr]="FR"
    [gb]="UK"
    [es]="ES"
    [it]="IT"
    [pt]="PT"
    [nl]="NL"
    [se]="SV"
    [no]="NO"
    [dk]="DA"
    [fi]="FI"
    [pl]="PL"
    [cz]="CS"
    [hu]="HU"
    [bg]="BG"
    [ru]="RU"
    [ua]="UA"
    [jp]="JP"
    [cn]="CN"
    [kr]="KR"
    [br]="BR"
    [latam]="LA"
)

format_layout() {
    local layout="${1,,}"
    printf '%s' "${LABELS[${layout}]:-${1^^}}"
}

case "${1:-}" in
    --polybar)
        current=$("$KBLAYOUT" get 2>/dev/null) || current="??"
        format_layout "$current"
        ;;
    --scroll-up)
        "$KBLAYOUT" next >/dev/null 2>&1
        ;;
    --scroll-down)
        "$KBLAYOUT" prev >/dev/null 2>&1
        ;;
    *)
        exec "$KBLAYOUT" "$@"
        ;;
esac
