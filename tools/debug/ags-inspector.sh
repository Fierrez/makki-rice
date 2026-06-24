#!/bin/bash
# =============================================================================
# tools/debug/ags-inspector.sh — Live AGS debug inspector
# =============================================================================
# Prints current AGS state and lets you run JS in the AGS context.
# Usage: ags-inspector.sh [eval "<js>"|windows|css-reset|island-mode|island-expand <mode>]
# =============================================================================

# shellcheck source=../../scripts/lib/ags-compat.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/lib/ags-compat.sh"

action="${1:-windows}"
arg="${2:-}"

case "$action" in
    eval)
        [[ -z "$arg" ]] && read -rp "JS to eval: " arg
        ags_run_blocking "$arg"
        ;;
    windows)
        echo "=== Open Windows ==="
        ags_run_blocking "JSON.stringify(App.windows.map(w => ({name: w.name, visible: w.visible})), null, 2)"
        ;;
    css-reset)
        ags_run_blocking "App.resetCss(); App.applyCss(App.configDir + '/style/main.css')"
        echo "CSS reset + reloaded."
        ;;
    island-mode)
        ags_run_blocking "mode?.value ?? 'unknown'"
        ;;
    island-expand)
        arg="${2:-volume}"
        ags_run_blocking "globalThis.islandExpand?.('$arg', 5000)"
        echo "Expanded island to: $arg (5s timeout)"
        ;;
    *)
        echo "Usage: ags-inspector.sh [eval <js>|windows|css-reset|island-mode|island-expand <mode>]"
        echo ""
        echo "Modes: idle, volume, brightness, battery, network, media"
        echo "AGS binary: ${AGS_BIN:-NOT FOUND — install: yay -S aylurs-gtk-shell}"
        ;;
esac
