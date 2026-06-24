#!/bin/bash
# =============================================================================
# scripts/system/audio.sh — Volume Control + AGS Signal Emitter
# =============================================================================
# Usage: audio.sh [up|down|mute|get]
# Emits AGS signal after change so island can react.
# =============================================================================

# shellcheck source=../lib/ags-compat.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/ags-compat.sh"

STEP=5    # Volume step percent
MAX=150   # Maximum volume percent (allow boost)

action="${1:-get}"

get_volume() {
    pamixer --get-volume
}

get_mute() {
    pamixer --get-mute
}

emit_ags_signal() {
    # Notify AGS about volume change (island expands)
    ags_run "App.getWindow('island') && globalThis.onVolumeChange?.()"
}

case "$action" in
    up)
        current=$(get_volume)
        new=$(( current + STEP ))
        [[ $new -gt $MAX ]] && new=$MAX
        pamixer --set-volume "$new"
        emit_ags_signal
        echo "Volume: $new%"
        ;;

    down)
        current=$(get_volume)
        new=$(( current - STEP ))
        [[ $new -lt 0 ]] && new=0
        pamixer --set-volume "$new"
        emit_ags_signal
        echo "Volume: $new%"
        ;;

    mute)
        pamixer --toggle-mute
        emit_ags_signal
        muted=$(get_mute)
        echo "Muted: $muted"
        ;;

    get)
        vol=$(get_volume)
        muted=$(get_mute)
        echo "{\"volume\": $vol, \"muted\": $muted}"
        ;;

    *)
        echo "Usage: audio.sh [up|down|mute|get]"
        exit 1
        ;;
esac
