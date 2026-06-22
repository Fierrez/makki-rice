#!/bin/bash
# =============================================================================
# services/hyprland/socket-handler.sh — Low-level Hyprland IPC Helper
# =============================================================================
# Provides utility functions for sending commands to Hyprland via socket.
# =============================================================================

SOCKET="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket.sock"

hypr_send() {
    local cmd="$1"
    echo -e "/$cmd" | socat - "UNIX-CONNECT:$SOCKET" 2>/dev/null
}

hypr_dispatch() {
    hypr_send "dispatch $*"
}

hypr_keyword() {
    hypr_send "keyword $*"
}

hypr_reload() {
    hypr_send "reload"
    echo "Hyprland config reloaded."
}

hypr_monitors() {
    hypr_send "monitors"
}

hypr_workspaces() {
    hypr_send "workspaces"
}

hypr_clients() {
    hypr_send "clients"
}

# Run as standalone
case "${1:-}" in
    dispatch)  shift; hypr_dispatch "$@" ;;
    keyword)   shift; hypr_keyword "$@" ;;
    reload)    hypr_reload ;;
    monitors)  hypr_monitors ;;
    workspaces) hypr_workspaces ;;
    clients)   hypr_clients ;;
    "")        echo "Available: dispatch, keyword, reload, monitors, workspaces, clients" ;;
    *)         echo "Unknown command: $1"; exit 1 ;;
esac
