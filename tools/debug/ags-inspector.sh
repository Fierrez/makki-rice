#!/bin/bash
# =============================================================================
# tools/debug/ags-inspector.sh — Live AGS debug inspector
# =============================================================================
# Prints current AGS state and lets you run JS in the AGS context.
# Usage: ags-inspector.sh [eval "<js>"|windows|css-reset]
# =============================================================================

action="${1:-windows}"
arg="${2:-}"

ags_r() {
    if command -v agsv1 &>/dev/null; then
        agsv1 -r "$1" 2>&1 || echo "AGS not running or eval failed."
    else
        ags -r "$1" 2>&1 || echo "AGS not running or eval failed."
    fi
}

case "$action" in
    eval)
        [[ -z "$arg" ]] && read -rp "JS to eval: " arg
        ags_r "$arg"
        ;;
    windows)
        echo "=== Open Windows ==="
        ags_r "JSON.stringify(App.windows.map(w => ({name: w.name, visible: w.visible})), null, 2)"
        ;;
    css-reset)
        ags_r "App.resetCss(); App.applyCss(App.configDir + '/style/main.css')"
        echo "CSS reset + reloaded."
        ;;
    island-mode)
        ags_r "mode?.value ?? 'unknown'"
        ;;
    island-expand)
        arg="${2:-volume}"
        ags_r "globalThis.islandExpand?.('$arg', 5000)"
        echo "Expanded island to: $arg (5s timeout)"
        ;;
    *)
        echo "Usage: ags-inspector.sh [eval <js>|windows|css-reset|island-mode|island-expand <mode>]"
        echo ""
        echo "Modes: idle, volume, brightness, battery, network, media"
        ;;
esac
