#!/bin/bash
# =============================================================================
# services/hyprland/event-router.sh — Hyprland Socket Event Router
# =============================================================================
# Listens to Hyprland IPC socket and routes events to scripts/AGS.
# This is the nervous system of the event-driven desktop.
# =============================================================================
#
# Event format from Hyprland socket2:
#   EVENT>>DATA\n
#
# Docs: https://wiki.hyprland.org/IPC/
# =============================================================================

set -euo pipefail

SOCKET="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
LOG_DIR="${HOME}/.local/share/makki-rice/logs"
LOG_FILE="$LOG_DIR/event-router.log"

mkdir -p "$LOG_DIR"

log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"; }

if [[ ! -S "$SOCKET" ]]; then
    log "ERROR: Hyprland socket not found at $SOCKET"
    echo "Error: Hyprland socket not found. Is Hyprland running?"
    exit 1
fi

log "Event router started. Listening on $SOCKET"

# ─── Event Handlers ──────────────────────────────────────────────────────────

on_workspace_change() {
    local ws="$1"
    log "Workspace: $ws"
    # Could trigger AGS workspace update here
}

on_active_window() {
    local class="$1"
    local title="$2"
    log "Active window: class=$class title=$title"
}

on_fullscreen() {
    local state="$1"
    log "Fullscreen: $state"
    # Hide dock when fullscreen
    if [[ "$state" == "1" ]]; then
        ags -r "App.getWindow('dock')?.hide()" 2>/dev/null || true
    else
        ags -r "App.getWindow('dock')?.show()" 2>/dev/null || true
    fi
}

on_monitor_added() {
    local monitor="$1"
    log "Monitor added: $monitor"
    # Re-initialize AGS on new monitor
    ags -r "App.resetMonitors?.()" 2>/dev/null || true
}

on_urgent() {
    local address="$1"
    log "Urgent window: $address"
}

# ─── Main Event Loop ──────────────────────────────────────────────────────────

socat -U - "UNIX-CONNECT:$SOCKET" | while IFS= read -r line; do
    event="${line%%>>*}"
    data="${line#*>>}"

    case "$event" in
        workspace)
            on_workspace_change "$data"
            ;;
        activewindow)
            IFS=',' read -r class title <<< "$data"
            on_active_window "$class" "$title"
            ;;
        fullscreen)
            on_fullscreen "$data"
            ;;
        monitoradded)
            on_monitor_added "$data"
            ;;
        urgent)
            on_urgent "$data"
            ;;
        openwindow|closewindow|movewindow)
            log "Window event: $event → $data"
            ;;
        *)
            # Silently ignore unhandled events
            ;;
    esac
done

log "Event router stopped."
