#!/bin/bash
# =============================================================================
# scripts/ui/dock.sh — Dock visibility control
# =============================================================================
# Usage: dock.sh [show|hide|toggle]
# =============================================================================

action="${1:-toggle}"

ags_run() {
    ags -r "$1" 2>/dev/null || true
}

case "$action" in
    show)    ags_run "globalThis.dockShow?.()" ;;
    hide)    ags_run "globalThis.dockHide?.()" ;;
    toggle)  ags_run "globalThis.dockVisible?.value ? globalThis.dockHide?.() : globalThis.dockShow?.()" ;;
    *)
        echo "Usage: dock.sh [show|hide|toggle]"
        exit 1
        ;;
esac
