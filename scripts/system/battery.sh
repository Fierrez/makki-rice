#!/bin/bash
# =============================================================================
# scripts/system/battery.sh — Battery Status Monitor
# =============================================================================
# Usage: battery.sh [status|watch]
# Watch mode emits AGS signals on critical state changes.
# =============================================================================

CRITICAL_THRESHOLD=10
LOW_THRESHOLD=20
POLL_INTERVAL=30  # seconds

get_battery_info() {
    local bat_path
    bat_path=$(find /sys/class/power_supply -name "BAT*" | head -1)

    [[ -z "$bat_path" ]] && echo '{"error": "no battery found"}' && return

    local capacity charging status icon
    capacity=$(cat "$bat_path/capacity" 2>/dev/null || echo "100")
    status=$(cat "$bat_path/status" 2>/dev/null || echo "Unknown")

    case "$status" in
        "Charging") charging="true";  icon="🔌" ;;
        "Full")     charging="true";  icon="⚡" ;;
        *)          charging="false"; icon="🔋" ;;
    esac

    echo "{\"percent\": $capacity, \"charging\": $charging, \"status\": \"$status\", \"icon\": \"$icon\"}"
}

notify_critical() {
    local pct="$1"
    notify-send -u critical -i battery-empty-symbolic \
        "Battery Critical!" "Battery at ${pct}%. Plug in now." 2>/dev/null || true
    ags -r "globalThis.onBatteryCritical?.(${pct})" 2>/dev/null || true
}

notify_low() {
    local pct="$1"
    notify-send -u normal -i battery-low-symbolic \
        "Battery Low" "Battery at ${pct}%." 2>/dev/null || true
}

case "${1:-status}" in
    status)
        get_battery_info
        ;;

    watch)
        echo "Watching battery..."
        last_state=""
        while true; do
            info=$(get_battery_info)
            pct=$(echo "$info" | jq -r '.percent // 100')
            charging=$(echo "$info" | jq -r '.charging // true')

            if [[ "$charging" == "false" ]]; then
                if (( pct <= CRITICAL_THRESHOLD )) && [[ "$last_state" != "critical" ]]; then
                    notify_critical "$pct"
                    last_state="critical"
                elif (( pct <= LOW_THRESHOLD && pct > CRITICAL_THRESHOLD )) && [[ "$last_state" != "low" ]]; then
                    notify_low "$pct"
                    last_state="low"
                elif (( pct > LOW_THRESHOLD )); then
                    last_state="normal"
                fi
            else
                last_state="charging"
            fi

            sleep "$POLL_INTERVAL"
        done
        ;;

    *)
        echo "Usage: battery.sh [status|watch]"
        exit 1
        ;;
esac
