#!/bin/bash
# scripts/hypr/monitor-setup.sh — Apply monitor config
# Usage: monitor-setup.sh [single|dual|laptop]

mode="${1:-single}"

case "$mode" in
    single)
        hyprctl keyword monitor "DP-1,2560x1440@165,0x0,1"
        ;;
    dual)
        hyprctl keyword monitor "DP-1,2560x1440@165,0x0,1"
        hyprctl keyword monitor "HDMI-A-1,1920x1080@60,2560x0,1"
        ;;
    laptop)
        hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1"
        ;;
    *)
        echo "Usage: monitor-setup.sh [single|dual|laptop]"
        exit 1
        ;;
esac

echo "Monitor mode set: $mode"
