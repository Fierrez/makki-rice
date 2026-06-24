#!/bin/bash
# =============================================================================
# scripts/ui/dock.sh — Dock visibility control
# =============================================================================
# Usage: dock.sh [show|hide|toggle]
# =============================================================================

# shellcheck source=../lib/ags-compat.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/ags-compat.sh"

action="${1:-toggle}"

case "$action" in
    show)    ags_run "globalThis.dockShow?.()" ;;
    hide)    ags_run "globalThis.dockHide?.()" ;;
    toggle)  ags_run "globalThis.dockVisible?.value ? globalThis.dockHide?.() : globalThis.dockShow?.()" ;;
    *)
        echo "Usage: dock.sh [show|hide|toggle]"
        exit 1
        ;;
esac
