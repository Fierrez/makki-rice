#!/bin/bash
# =============================================================================
# scripts/ui/workspace.sh — Workspace helpers for scripts/bars
# =============================================================================
# Usage: workspace.sh [list|active|goto <n>|move <n>|next|prev]
# =============================================================================

action="${1:-list}"
arg="${2:-}"

case "$action" in
    list)
        hyprctl workspaces -j | jq '[.[] | {id: .id, name: .name, windows: .windows}]'
        ;;
    active)
        hyprctl activeworkspace -j | jq '{id: .id, name: .name, windows: .windows}'
        ;;
    goto)
        [[ -z "$arg" ]] && echo "Usage: workspace.sh goto <n>" && exit 1
        hyprctl dispatch workspace "$arg"
        ;;
    move)
        [[ -z "$arg" ]] && echo "Usage: workspace.sh move <n>" && exit 1
        hyprctl dispatch movetoworkspace "$arg"
        ;;
    next)
        hyprctl dispatch workspace e+1
        ;;
    prev)
        hyprctl dispatch workspace e-1
        ;;
    *)
        echo "Usage: workspace.sh [list|active|goto <n>|move <n>|next|prev]"
        exit 1
        ;;
esac
