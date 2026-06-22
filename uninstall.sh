#!/bin/bash
# =============================================================================
# uninstall.sh — Rice Uninstaller
# =============================================================================
# Removes symlinks, services, and optionally backs up configs.
# Does NOT remove installed packages (safety measure).
# =============================================================================

set -euo pipefail

CONFIG_TARGET="$HOME/.config"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()  { echo -e "${GREEN}[✓]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $*"; }
step()  { echo -e "\n${CYAN}[→]${RESET} ${BOLD}$*${RESET}"; }

remove_link() {
    local path="$1"
    if [[ -L "$path" ]]; then
        rm "$path"
        info "Removed symlink: $path"
        # Restore backup if exists
        if [[ -d "${path}.bak" ]]; then
            mv "${path}.bak" "$path"
            info "Restored backup: ${path}.bak → $path"
        fi
    else
        warn "Not a symlink (skipping): $path"
    fi
}

remove_service() {
    local service="hypr-rice.service"
    if systemctl --user is-enabled "$service" &>/dev/null; then
        systemctl --user disable --now "$service" 2>/dev/null || true
        rm -f "$HOME/.config/systemd/user/$service"
        systemctl --user daemon-reload
        info "Service removed: $service"
    else
        warn "Service not active: $service"
    fi
}

main() {
    echo -e "${BOLD}${RED}Makki Rice Uninstaller${RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    read -rp "This will remove all rice symlinks. Continue? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

    step "Removing config symlinks..."
    for dir in hypr waybar wofi rofi swaync ags; do
        remove_link "$CONFIG_TARGET/$dir"
    done

    step "Removing systemd service..."
    remove_service

    echo ""
    info "Uninstall complete. Packages were NOT removed."
}

main "$@"
