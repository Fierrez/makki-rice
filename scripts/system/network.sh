#!/bin/bash
# =============================================================================
# scripts/system/network.sh — Network Status
# =============================================================================
# Usage: network.sh [status|ssid|icon]
# =============================================================================

action="${1:-status}"

get_ssid() {
    nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2
}

get_status() {
    local ssid state ip
    ssid=$(get_ssid)
    state=$(nmcli networking connectivity 2>/dev/null || echo "unknown")
    ip=$(hostname -I 2>/dev/null | awk '{print $1}')

    echo "{\"ssid\": \"${ssid:-Disconnected}\", \"connectivity\": \"$state\", \"ip\": \"${ip:-N/A}\"}"
}

get_icon() {
    local ssid
    ssid=$(get_ssid)
    if [[ -n "$ssid" ]]; then
        local strength
        strength=$(nmcli -t -f active,signal dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
        if   (( strength > 75 )); then echo "network-wireless-signal-excellent-symbolic"
        elif (( strength > 50 )); then echo "network-wireless-signal-good-symbolic"
        elif (( strength > 25 )); then echo "network-wireless-signal-ok-symbolic"
        else echo "network-wireless-signal-weak-symbolic"
        fi
    else
        echo "network-offline-symbolic"
    fi
}

case "$action" in
    status) get_status ;;
    ssid)   get_ssid || echo "Disconnected" ;;
    icon)   get_icon ;;
    *)      echo "Usage: network.sh [status|ssid|icon]"; exit 1 ;;
esac
