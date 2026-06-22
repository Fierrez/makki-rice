#!/bin/bash
# =============================================================================
# scripts/bootstrap/link-config.sh — Symlink Config Files
# =============================================================================

set -euo pipefail

RICE_DIR="${RICE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CONFIG="$HOME/.config"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
info() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }

safe_link() {
    local src="$1"
    local dst="$2"

    [[ ! -e "$src" ]] && warn "Source missing: $src" && return

    if [[ -L "$dst" ]]; then
        rm "$dst"
    elif [[ -e "$dst" ]]; then
        warn "Backing up: $dst → $dst.bak.$(date +%s)"
        mv "$dst" "$dst.bak.$(date +%s)"
    fi

    ln -sf "$src" "$dst"
    info "Linked: $(basename "$src") → $dst"
}

main() {
    # Config directories
    safe_link "$RICE_DIR/config/hypr"   "$CONFIG/hypr"
    safe_link "$RICE_DIR/config/waybar" "$CONFIG/waybar"
    safe_link "$RICE_DIR/config/wofi"   "$CONFIG/wofi"
    safe_link "$RICE_DIR/config/rofi"   "$CONFIG/rofi"
    safe_link "$RICE_DIR/config/swaync" "$CONFIG/swaync"

    # AGS
    safe_link "$RICE_DIR/ui-engine/ags" "$CONFIG/ags"

    # Self-reference (for service scripts)
    safe_link "$RICE_DIR" "$CONFIG/makki-rice"

    # Screenshots dir
    mkdir -p "$HOME/Pictures/Screenshots"
    info "Created: ~/Pictures/Screenshots"
}

main "$@"
