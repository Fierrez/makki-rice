#!/bin/bash
# =============================================================================
# scripts/bootstrap/init.sh — Post-install Initialization
# =============================================================================
# Runs after packages are installed and configs are linked.
# Sets up GTK theme, cursor, icons, fonts, systemd services.
# =============================================================================

set -euo pipefail

RICE_DIR="${RICE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
info() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }

# ─── GTK Theme ────────────────────────────────────────────────────────────────
setup_gtk() {
    info "Setting GTK theme..."
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

    cat > "$HOME/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Catppuccin-Mocha-Standard-Blue-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-font-name=JetBrains Mono Nerd Font 11
gtk-application-prefer-dark-theme=1
EOF

    cat > "$HOME/.config/gtk-4.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Catppuccin-Mocha-Standard-Blue-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-font-name=JetBrains Mono Nerd Font 11
gtk-application-prefer-dark-theme=1
EOF
    info "GTK theme configured."
}

# ─── Cursor ───────────────────────────────────────────────────────────────────
setup_cursor() {
    info "Setting cursor theme..."
    mkdir -p "$HOME/.icons/default"
    cat > "$HOME/.icons/default/index.theme" << 'EOF'
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=Bibata-Modern-Ice
EOF
    info "Cursor configured."
}

# ─── Font Cache ───────────────────────────────────────────────────────────────
setup_fonts() {
    info "Rebuilding font cache..."
    fc-cache -fv 2>/dev/null || warn "fc-cache failed; fonts may need manual refresh."
}

# ─── Systemd User Service ─────────────────────────────────────────────────────
setup_systemd() {
    local service_src="$RICE_DIR/services/systemd/hypr-rice.service"
    local service_dst="$HOME/.config/systemd/user/hypr-rice.service"

    if [[ -f "$service_src" ]] && command -v systemctl &>/dev/null; then
        mkdir -p "$(dirname "$service_dst")"
        cp "$service_src" "$service_dst"
        systemctl --user daemon-reload
        systemctl --user enable hypr-rice.service 2>/dev/null || warn "Could not enable service (Hyprland not running)."
        info "Systemd service configured."
    fi
}

# ─── Wallpaper Placeholder ────────────────────────────────────────────────────
setup_wallpaper() {
    local wp_dir="$RICE_DIR/assets/wallpapers"
    if [[ ! -f "$wp_dir/default.jpg" ]]; then
        warn "No default wallpaper found at $wp_dir/default.jpg"
        warn "Add a wallpaper there, or awww will fail on boot."
    else
        info "Default wallpaper found."
    fi
}

setup_hw_detection() {
    info "Running hardware and VM environment detector..."
    bash "$RICE_DIR/scripts/system/detect-hw.sh" ${HW_MODE:-}
}

main() {
    setup_gtk
    setup_cursor
    setup_fonts
    setup_systemd
    setup_wallpaper
    setup_hw_detection
    info "Initialization complete."
}

main "$@"
