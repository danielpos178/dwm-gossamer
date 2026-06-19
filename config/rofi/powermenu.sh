#!/usr/bin/env bash
# Power menu mode for Rofi
# Usage: rofi -show powermenu -modi "powermenu:$0"

set -e
set -u

# ── Supported choices ────────────────────────────────────────────────────────
all=(shutdown reboot suspend hibernate logout lockscreen)
show=("${all[@]}")

# ── Text labels ──────────────────────────────────────────────────────────────
declare -A texts
texts[lockscreen]="lock screen"
texts[logout]="log out"
texts[suspend]="suspend"
texts[hibernate]="hibernate"
texts[reboot]="reboot"
texts[shutdown]="shut down"

# ── Icons (Nerd Font + Material) ─────────────────────────────────────────────
declare -A icons
declare -A nerd_font_icons
declare -A material_icons

nerd_font_icons[lockscreen]=$'\Uf033e'
nerd_font_icons[logout]=$'\Uf0343'
nerd_font_icons[suspend]=$'\Uf04b2'
nerd_font_icons[hibernate]=$'\Uf02ca'
nerd_font_icons[reboot]=$'\Uf0709'
nerd_font_icons[shutdown]=$'\Uf0425'
nerd_font_icons[cancel]=$'\Uf0156'

material_icons[lockscreen]="lock"
material_icons[logout]="logout"
material_icons[suspend]="bedtime"
material_icons[hibernate]="hotel"
material_icons[reboot]="restart_alt"
material_icons[shutdown]="power_settings_new"
material_icons[cancel]="close"

# ── Actions (init-system aware) ──────────────────────────────────────────────
declare -A actions
actions[lockscreen]="loginctl lock-session ${XDG_SESSION_ID-}"
actions[logout]="loginctl terminate-session ${XDG_SESSION_ID-}"

if [ -d /run/systemd/system ]; then
    # systemd (Arch, Fedora, etc.)
    actions[suspend]="systemctl suspend"
    actions[hibernate]="systemctl hibernate"
    actions[reboot]="systemctl reboot"
    actions[shutdown]="systemctl poweroff"
else
    # runit (Void Linux) — direct power commands
    actions[suspend]="zzz"
    actions[hibernate]="ZZZ"
    actions[reboot]="reboot"
    actions[shutdown]="poweroff"
fi

# Actions requiring confirmation before executing
confirmations=(reboot shutdown logout)

# ── Defaults ─────────────────────────────────────────────────────────────────
dryrun=false
showsymbols=true
showtext=true

# ── Font helpers ─────────────────────────────────────────────────────────────
font_exists() {
    fc-match "$1" 2>/dev/null | command grep -Fqi "$1"
}

detect_symbols_font() {
    local candidate
    for candidate in \
        "Material Icons" \
        "Material Icons Outlined" \
        "Material Icons Round" \
        "Material Icons Sharp" \
        "Material Icons Two Tone" \
        "Symbols Nerd Font Mono" \
        "Symbols Nerd Font" \
        "MesloLGS NF" \
        "MesloLGS Nerd Font" \
        "MesloLGS Nerd Font Mono"
    do
        if font_exists "$candidate"; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

set_icons() {
    local font="$1" entry
    case "$font" in
        "Material Icons"|"Material Icons Outlined"|"Material Icons Round"|"Material Icons Sharp"|"Material Icons Two Tone")
            for entry in "${!material_icons[@]}"; do
                icons[$entry]="${material_icons[$entry]}"
            done
            ;;
        *)
            for entry in "${!nerd_font_icons[@]}"; do
                icons[$entry]="${nerd_font_icons[$entry]}"
            done
            ;;
    esac
}

symbols_font=""
if detected_symbols_font=$(detect_symbols_font); then
    symbols_font="$detected_symbols_font"
fi
set_icons "$symbols_font"

# ── Validation ───────────────────────────────────────────────────────────────
require_valid_action() {
    local option="$1"; shift
    local entry
    for entry in "${@}"; do
        if [ -z "${actions[$entry]+x}" ]; then
            echo "Invalid choice in $option: $entry" >&2
            exit 1
        fi
    done
}

# ── Parse CLI options ────────────────────────────────────────────────────────
parsed=$(getopt --options=h \
    --longoptions=help,dry-run,confirm:,choices:,choose:,symbols,no-symbols,text,no-text,symbols-font: \
    --name "$0" -- "$@")
if [ $? -ne 0 ]; then
    echo 'Terminating...' >&2
    exit 1
fi
eval set -- "$parsed"
unset parsed

while true; do
    case "$1" in
        "-h"|"--help")
            echo "rofi-power-menu — a power menu mode for Rofi"
            echo
            echo "Usage: rofi-power-menu [--choices CHOICES] [--confirm CHOICES]"
            echo "                       [--choose CHOICE] [--dry-run] [--symbols|--no-symbols]"
            echo
            echo "Available choices: shutdown, reboot, suspend, hibernate, logout, lockscreen"
            exit 0
            ;;
        "--dry-run")      dryrun=true;       shift 1 ;;
        "--symbols")     showsymbols=true;  shift 1 ;;
        "--no-symbols")  showsymbols=false; shift 1 ;;
        "--text")        showtext=true;     shift 1 ;;
        "--no-text")     showtext=false;    shift 1 ;;
        "--confirm")
            IFS='/' read -ra confirmations <<< "$2"
            require_valid_action "$1" "${confirmations[@]}"
            shift 2
            ;;
        "--choices")
            IFS='/' read -ra show <<< "$2"
            require_valid_action "$1" "${show[@]}"
            shift 2
            ;;
        "--choose")
            require_valid_action "$1" "$2"
            selectionID="$2"
            shift 2
            ;;
        "--symbols-font")
            symbols_font="$2"
            set_icons "$symbols_font"
            shift 2
            ;;
        "--") shift; break ;;
        *)    echo "Internal error" >&2; exit 1 ;;
    esac
done

if [ "$showsymbols" = "false" ] && [ "$showtext" = "false" ]; then
    echo "Invalid options: cannot have --no-symbols and --no-text at the same time." >&2
    exit 1
fi

# ── Message builders ─────────────────────────────────────────────────────────
write_message() {
    local icon text
    if [ -n "$symbols_font" ]; then
        icon="<span font=\"${symbols_font}\" font_size=\"medium\">$1</span>"
    else
        icon="<span font_size=\"medium\">$1</span>"
    fi
    text="<span font_size=\"medium\">$2</span>"

    if [ "$showsymbols" = "true" ]; then
        if [ "$showtext" = "true" ]; then
            printf '\u200e%s \u2068%s\u2069' "$icon" "$text"
        else
            printf '\u200e%s' "$icon"
        fi
    else
        printf '%s' "$text"
    fi
}

print_selection() {
    printf '%b' "$1"
}

# ── Build message tables ────────────────────────────────────────────────────
declare -A messages
declare -A confirmationMessages

for entry in "${all[@]}"; do
    messages[$entry]=$(write_message "${icons[$entry]}" "${texts[$entry]^}")
    # Zero-width space in icon prevents confirmation messages colliding with regular ones
    confirmationMessages[$entry]=$(write_message "${icons[$entry]}\u200b" "Yes, ${texts[$entry]}")
done
confirmationMessages[cancel]=$(write_message "${icons[cancel]}" "No, cancel")

# ── Determine selection ──────────────────────────────────────────────────────
if [ $# -gt 0 ]; then
    selection="$*"
elif [ -n "${selectionID+x}" ]; then
    selection="${messages[$selectionID]}"
fi

# ── If not invoked by rofi, launch rofi with this script as the mode ─────────
if [ -z "${ROFI_RETV+x}" ]; then
    exec rofi -show powermenu -modi "powermenu:$0" \
        -config "$HOME/.config/rofi/config.rasi" \
        -theme-str 'window { location: center; anchor: center; height: 215px; width: 200px; border: 2px solid; margin: 0; } mainbox { margin: 0; spacing: 0; } listview { margin: 0; spacing: 0; } inputbar { enabled: false; }'
fi

# ── Rofi protocol headers ───────────────────────────────────────────────────
echo -e "\0no-custom\x1ftrue"
echo -e "\0markup-rows\x1ftrue"

# ── No selection yet → show menu ─────────────────────────────────────────────
if [ -z "${selection+x}" ]; then
    echo -e "\0prompt\x1fPower menu"
    for entry in "${show[@]}"; do
        echo -e "${messages[$entry]}"
    done
    exit 0
fi

# ── Selection received → find matching action ────────────────────────────────
for entry in "${show[@]}"; do
    # Match against the regular message (user clicked an item)
    if [ "$selection" = "$(print_selection "${messages[$entry]}")" ]; then
        # Check if this action requires confirmation
        for conf in "${confirmations[@]}"; do
            if [ "$entry" = "$conf" ]; then
                echo -e "\0prompt\x1fAre you sure"
                echo -e "${confirmationMessages[$entry]}"
                echo -e "${confirmationMessages[cancel]}"
                exit 0
            fi
        done
        # No confirmation needed — execute directly
        if [ "$dryrun" = true ]; then
            echo "Selected: $entry" >&2
        else
            ${actions[$entry]}
        fi
        exit 0
    fi

    # Match against the confirmation message (user confirmed)
    if [ "$selection" = "$(print_selection "${confirmationMessages[$entry]}")" ]; then
        if [ "$dryrun" = true ]; then
            echo "Selected: $entry" >&2
        else
            ${actions[$entry]}
        fi
        exit 0
    fi

    # Match against cancel
    if [ "$selection" = "$(print_selection "${confirmationMessages[cancel]}")" ]; then
        exit 0
    fi
done

echo "Invalid selection: $selection" >&2
exit 1
