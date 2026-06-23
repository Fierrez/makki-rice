#!/bin/bash
# =============================================================================
# scripts/hypr/reload.sh — Hyprland Config Reload
# =============================================================================
# Reloads Hyprland config and optionally restarts AGS.
# Usage: reload.sh [--ags] [--css]
# =============================================================================

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
info() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }

if ! command -v hyprctl &>/dev/null; then
    echo "hyprctl not found — is Hyprland running?"
    exit 1
fi

info "Reloading Hyprland config..."
hyprctl reload && info "Hyprland config reloaded." || warn "Hyprland reload failed"

# Check for configuration errors immediately
RICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bash "$RICE_DIR/scripts/hypr/config-check.sh" || true

for arg in "$@"; do
    case "$arg" in
        --ags)
            info "Restarting AGS..."
            pkill -x ags 2>/dev/null || true
            sleep 0.3
            ags &
            info "AGS restarted."
            ;;
        --css)
            info "Rebuilding CSS..."
            RICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
            bash "$RICE_DIR/tools/dev/build-css.sh"
            ;;
    esac
done

info "Done."
