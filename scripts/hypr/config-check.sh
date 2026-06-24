#!/bin/bash
# =============================================================================
# scripts/hypr/config-check.sh — Capture & export Hyprland config errors
# =============================================================================
# Runs hyprctl configerrors, saves formatted output to logs, and alerts user.
# =============================================================================

set -uo pipefail

LOG_DIR="${HOME}/.local/share/makki-rice/logs"
LOG_FILE="$LOG_DIR/hyprland-config-errors.log"
mkdir -p "$LOG_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'

info() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
error() { echo -e "${RED}[✗]${RESET} $*"; }

# ─── Verification ────────────────────────────────────────────────────────────
if ! command -v hyprctl &>/dev/null; then
    error "hyprctl not found — is Hyprland running?"
    exit 1
fi

# Run hyprctl configerrors
# First check if JSON format is available
raw_errors=$(hyprctl -j configerrors 2>/dev/null)
has_json=false
if [[ $? -eq 0 && -n "$raw_errors" ]]; then
    has_json=true
fi

if [[ "$has_json" == "true" ]]; then
    if command -v jq &>/dev/null; then
        error_count=$(echo "$raw_errors" | jq 'length' 2>/dev/null || echo 0)
    else
        error_count=$(echo "$raw_errors" | grep -c '"error"' || echo 0)
    fi
else
    raw_errors=$(hyprctl configerrors 2>/dev/null)
    if [[ "$raw_errors" == "no errors found" || -z "$raw_errors" ]]; then
        error_count=0
    else
        error_count=$(echo "$raw_errors" | grep -c '^' || echo 0)
    fi
fi

# Sanitize error_count to ensure it is a clean integer (stripping carriage returns/spaces)
error_count=$(echo "$error_count" | tr -cd '0-9')
error_count=${error_count:-0}

# ─── Log and Alert ────────────────────────────────────────────────────────────
if [[ "$error_count" -gt 0 ]]; then
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log rotation or simple boundary is clear
    {
        echo "============================================================================="
        echo "Hyprland Configuration Errors detected at $timestamp"
        echo "Total errors: $error_count"
        echo "============================================================================="
        if [[ "$has_json" == "true" ]]; then
            if command -v jq &>/dev/null; then
                echo "$raw_errors" | jq -r '.[] | "Line \(.line): \(.error)"'
            else
                echo "$raw_errors"
            fi
        else
            echo "$raw_errors"
        fi
        echo -e "\n"
    } >> "$LOG_FILE"

    error "Detected $error_count Hyprland configuration error(s)!"
    warn "Detailed report written to: $LOG_FILE"

    # Dispatch native notification via notify-send
    if command -v notify-send &>/dev/null; then
        notify-send -u critical -i "dialog-error-symbolic" \
            "Hyprland Config Errors" \
            "Detected $error_count configuration error(s).\nDetails saved to: $LOG_FILE" 2>/dev/null &
    fi

    # Dispatch notification to AGS bridge if running
    if pgrep -x agsv1 &>/dev/null; then
        agsv1 -r "globalThis.routerNotify?.('configerrors', '$error_count errors found. Check logs.')" 2>/dev/null &
    elif pgrep -x ags &>/dev/null; then
        ags -r "globalThis.routerNotify?.('configerrors', '$error_count errors found. Check logs.')" 2>/dev/null &
    fi
    
    exit 1
else
    info "No Hyprland configuration errors found."
    exit 0
fi
