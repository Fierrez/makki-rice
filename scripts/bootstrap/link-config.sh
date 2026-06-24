#!/bin/bash
# =============================================================================
# scripts/bootstrap/link-config.sh — Symlink Config Files
# =============================================================================

set -euo pipefail

RICE_DIR="${RICE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
CONFIG="$HOME/.config"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
info() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }

safe_link() {
    local src="$1"
    local dst="$2"

    [[ ! -e "$src" ]] && warn "Source missing: $src" && return

    # Clean up broken/looped symlinks at destination if they exist
    if [[ -L "$dst" ]]; then
        if ! realpath "$dst" &>/dev/null; then
            warn "Removing broken or circular symlink: $dst"
            rm -f "$dst"
        fi
    fi

    # Avoid self-referencing symlink loops
    local canonical_src; canonical_src=$(realpath -f "$src" 2>/dev/null || echo "$src")
    local canonical_dst; canonical_dst=$(realpath -f "$dst" 2>/dev/null || echo "$dst")
    if [[ "$canonical_src" == "$canonical_dst" ]]; then
        info "Already linked: $(basename "$src") → $dst"
        return
    fi

    if [[ -L "$dst" ]]; then
        rm "$dst"
    elif [[ -e "$dst" ]]; then
        if [[ "${FORCE_OVERWRITE:-false}" == "true" ]]; then
            info "Overwriting: $dst"
            rm -rf "$dst"
        else
            warn "Backing up: $dst → $dst.bak.$(date +%s)"
            mv "$dst" "$dst.bak.$(date +%s)"
        fi
    fi

    ln -sf "$src" "$dst"
    info "Linked: $(basename "$src") → $dst"
}

main() {
    # Ensure hw-env.conf exists so Hyprland doesn't throw a globbing/sourcing error
    if [[ ! -f "$RICE_DIR/config/hypr/hw-env.conf" ]]; then
        echo "# Placeholder for hardware overrides" > "$RICE_DIR/config/hypr/hw-env.conf"
    fi

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

    # CLI Binary
    mkdir -p "$HOME/.local/bin"
    safe_link "$RICE_DIR/makki-rice" "$HOME/.local/bin/makki-rice"

    # Screenshots dir
    mkdir -p "$HOME/Pictures/Screenshots"
    info "Created: ~/Pictures/Screenshots"
}

main "$@"
