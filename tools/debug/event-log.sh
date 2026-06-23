#!/bin/bash
# =============================================================================
# tools/debug/event-log.sh — Live Event Log Viewer
# =============================================================================
# Pretty-prints the event-router JSON log in real time.
# Requires: jq
#
# Usage:
#   event-log.sh              # tail live
#   event-log.sh filter <ev>  # filter by event type
#   event-log.sh stats        # event frequency stats
#   event-log.sh last <n>     # show last N events
# =============================================================================

LOG="${HOME}/.local/share/makki-rice/logs/event-router.log"

# Colors
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; DIM='\033[2m'; BOLD='\033[1m'; RESET='\033[0m'

check_log() {
    [[ -f "$LOG" ]] || { echo "No log file at: $LOG"; exit 1; }
}

color_level() {
    local level="$1"
    case "$level" in
        EVENT) echo -e "${CYAN}EVENT${RESET}" ;;
        INFO)  echo -e "${GREEN}INFO ${RESET}" ;;
        WARN)  echo -e "${YELLOW}WARN ${RESET}" ;;
        ERROR) echo -e "${RED}ERROR${RESET}" ;;
        *)     echo "$level" ;;
    esac
}

format_line() {
    local line="$1"
    # Try JSON parse
    if echo "$line" | jq -e . &>/dev/null 2>&1; then
        local ts level msg
        ts=$(echo "$line" | jq -r '.ts // "?"')
        level=$(echo "$line" | jq -r '.level // "?"')
        msg=$(echo "$line" | jq -r '.msg // ""')
        printf "${DIM}%s${RESET} [%s] %s\n" \
            "${ts##*T}" "$(color_level "$level")" "$msg"
    else
        echo "$line"
    fi
}

action="${1:-live}"

case "$action" in
    live)
        check_log
        echo -e "${BOLD}Live event log${RESET} (${DIM}$LOG${RESET})"
        echo "──────────────────────────────────────────"
        tail -f "$LOG" | while IFS= read -r line; do
            format_line "$line"
        done
        ;;

    filter)
        check_log
        keyword="${2:-EVENT}"
        echo -e "${BOLD}Filtering:${RESET} $keyword"
        grep --line-buffered "\"$keyword\"" "$LOG" | while IFS= read -r line; do
            format_line "$line"
        done
        ;;

    last)
        check_log
        n="${2:-50}"
        tail -n "$n" "$LOG" | while IFS= read -r line; do
            format_line "$line"
        done
        ;;

    stats)
        check_log
        echo -e "${BOLD}Event frequency (all time):${RESET}"
        echo "──────────────────────────────────────────"
        grep -o '"EVENT"' "$LOG" | wc -l | xargs printf "Total events: %s\n"
        echo ""
        echo "Top event types:"
        grep '"level":"EVENT"' "$LOG" \
            | jq -r '.msg' 2>/dev/null \
            | grep -oP '^\w+' \
            | sort | uniq -c | sort -rn \
            | head -20 \
            | awk '{printf "  %-6s %s\n", $1, $2}'
        ;;

    clear)
        read -rp "Clear log? [y/N] " c
        [[ "$c" =~ ^[Yy]$ ]] && > "$LOG" && echo "Log cleared."
        ;;

    *)
        echo "Usage: event-log.sh [live|filter <keyword>|last <n>|stats|clear]"
        ;;
esac
