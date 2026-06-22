#!/bin/bash
# scripts/hypr/restart.sh — Kill and relaunch Hyprland
pkill -x Hyprland || true
sleep 0.5
exec Hyprland
