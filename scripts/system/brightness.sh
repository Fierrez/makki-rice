#!/bin/bash
# =============================================================================
# scripts/system/brightness.sh — Screen Brightness Control
# =============================================================================
# Usage: brightness.sh [up|down|set <val>|get]
# Uses brightnessctl. Emits AGS signal.
# =============================================================================

# shellcheck source=../lib/ags-compat.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/ags-compat.sh"

STEP=5   # Brightness step percent

action="${1:-get}"
value="${2:-}"

get_brightness() {
    brightnessctl -m | awk -F, '{print substr($4, 1, length($4)-1)}'
}

emit_ags_signal() {
    ags_run "globalThis.onBrightnessChange?.()"
}

case "$action" in
    up)
        brightnessctl set "${STEP}%+"
        emit_ags_signal
        echo "Brightness: $(get_brightness)%"
        ;;

    down)
        brightnessctl set "${STEP}%-"
        emit_ags_signal
        echo "Brightness: $(get_brightness)%"
        ;;

    set)
        [[ -z "$value" ]] && { echo "Usage: brightness.sh set <0-100>"; exit 1; }
        brightnessctl set "${value}%"
        emit_ags_signal
        echo "Brightness: $(get_brightness)%"
        ;;

    get)
        echo "Brightness: $(get_brightness)%"
        ;;

    *)
        echo "Usage: brightness.sh [up|down|set <val>|get]"
        exit 1
        ;;
esac
