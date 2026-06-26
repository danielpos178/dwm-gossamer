#!/bin/bash

COLOR_ACTIVE="${DWM_TAG_ACTIVE_COLOR:-#eceff4}"
COLOR_OCCUPIED="${DWM_TAG_OCCUPIED_COLOR:-#d8dee9}"
COLOR_URGENT="${DWM_TAG_URGENT_COLOR:-#bf616a}"
FONT_ACTIVE="${DWM_TAG_ACTIVE_FONT:-2}"
FONT_OCCUPIED="${DWM_TAG_OCCUPIED_FONT:-4}"
FONT_URGENT="${DWM_TAG_URGENT_FONT:-3}"

update_tags() {

declare -A occupied_tags
declare -A urgent_tags
client_list=$(xprop -root _NET_CLIENT_LIST 2>/dev/null | cut -d'#' -f2)

if [ -n "$client_list" ]; then
    for win_id in $(echo "$client_list" | tr ',' '\n' | tr -d ' '); do
        if [ -n "$win_id" ]; then
            desktop=$(xprop -id "$win_id" _NET_WM_DESKTOP 2>/dev/null | awk '{print $3}')
            # Skip sticky windows (4294967295 = all desktops)
            if [ -n "$desktop" ] && [ "$desktop" != "4294967295" ]; then
                occupied_tags[$desktop]=1
                
                # Check for urgent hint
                hints=$(xprop -id "$win_id" WM_HINTS 2>/dev/null)
                if echo "$hints" | command grep -q "urgency hint"; then
                    urgent_tags[$desktop]=1
                fi
            fi
        fi
    done
fi

    current=$(xprop -root _NET_CURRENT_DESKTOP 2>/dev/null | awk '{print $3}')
    current=${current:-0}

    output=""
    has_output=false
    for i in {0..8}; do
        tag=$((i + 1))
        if [ "$i" = "$current" ]; then
            output+="%{F${COLOR_ACTIVE}}%{T${FONT_ACTIVE}}$tag%{T-}%{F-} "
            has_output=true
        elif [ "${urgent_tags[$i]}" = "1" ]; then
            output+="%{F${COLOR_URGENT}}%{T${FONT_URGENT}}$tag%{T-}%{F-} "
            has_output=true
        elif [ "${occupied_tags[$i]}" = "1" ]; then
            output+="%{F${COLOR_OCCUPIED}}%{T${FONT_OCCUPIED}}$tag%{T-}%{F-} "
            has_output=true
        fi
    done

    if [ "$has_output" = true ]; then
        echo "$output"
    else
        echo " "
    fi
}

if [ "$1" = "--tail" ]; then
    update_tags
    
    # Listen for property changes that indicate desktop/tag changes
    # Monitors: DWM_TAG_UPDATE (custom signal), _NET_CURRENT_DESKTOP (active desktop), 
    # and _NET_CLIENT_LIST (window list changes)
    xprop -root -spy DWM_TAG_UPDATE _NET_CURRENT_DESKTOP _NET_CLIENT_LIST 2>/dev/null | \
    while read -r line; do
        update_tags
    done
else
    update_tags
fi
