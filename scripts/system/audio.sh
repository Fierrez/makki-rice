#!/bin/bash
# =============================================================================
# scripts/system/audio.sh — Volume Control + AGS Signal Emitter
# =============================================================================
# Usage: audio.sh [up|down|mute|get]
# Emits AGS signal after change so island can react.
# =============================================================================

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
    if command -v agsv1 &>/dev/null; then
        agsv1 -r "App.getWindow('island') && globalThis.onVolumeChange?.()" 2>/dev/null || true
    else
        ags -r "App.getWindow('island') && globalThis.onVolumeChange?.()" 2>/dev/null || true
    fi
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
