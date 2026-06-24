#!/bin/bash
# =============================================================================
# scripts/ui/island.sh — Island control bridge
# =============================================================================
# Allows shell scripts to trigger island expansion from outside AGS.
# Usage: island.sh [volume|brightness|battery|network|media|collapse]
# =============================================================================

# shellcheck source=../lib/ags-compat.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/ags-compat.sh"

action="${1:-collapse}"
duration="${2:-3000}"

case "$action" in
    volume)
        ags_run "globalThis.islandExpand?.('volume', $duration)"
        ;;
    brightness)
        ags_run "globalThis.islandExpand?.('brightness', $duration)"
        ;;
    battery)
        ags_run "globalThis.islandExpand?.('battery', $duration)"
        ;;
    network)
        ags_run "globalThis.islandExpand?.('network', $duration)"
        ;;
    media)
        ags_run "globalThis.islandExpand?.('media', $duration)"
        ;;
    collapse)
        ags_run "globalThis.islandCollapse?.()"
        ;;
    *)
        echo "Usage: island.sh [volume|brightness|battery|network|media|collapse] [duration_ms]"
        exit 1
        ;;
esac
