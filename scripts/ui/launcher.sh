#!/bin/bash
# =============================================================================
# scripts/ui/launcher.sh — Toggle app launcher
# =============================================================================
# Usage: launcher.sh [open|close|toggle]
# Uses wofi by default, falls back to rofi, then AGS launcher.
# =============================================================================

# shellcheck source=../lib/ags-compat.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/ags-compat.sh"

action="${1:-toggle}"

WOFI_PID=$(pgrep -x wofi || true)
ROFI_PID=$(pgrep -x rofi || true)

open_launcher() {
    if command -v wofi &>/dev/null; then
        wofi --show drun --allow-images --allow-markup \
             --gtk-dark --conf ~/.config/wofi/config \
             --style ~/.config/wofi/style.css &
    elif command -v rofi &>/dev/null; then
        rofi -show drun -theme ~/.config/rofi/mocha.rasi &
    else
        ags_run "App.getWindow('launcher')?.show()"
    fi
}

close_launcher() {
    pkill -x wofi 2>/dev/null || true
    pkill -x rofi 2>/dev/null || true
    ags_run "App.getWindow('launcher')?.hide()"
}

case "$action" in
    open)   open_launcher ;;
    close)  close_launcher ;;
    toggle)
        if [[ -n "$WOFI_PID" || -n "$ROFI_PID" ]]; then
            close_launcher
        else
            open_launcher
        fi
        ;;
    *)
        echo "Usage: launcher.sh [open|close|toggle]"
        exit 1
        ;;
esac
