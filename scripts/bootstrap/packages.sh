#!/bin/bash
# =============================================================================
# scripts/bootstrap/packages.sh — Package Installer
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
info() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }

PACMAN_PACKAGES=(
    # Compositor
    hyprland hyprpaper hyprpicker hypridle hyprlock xdg-desktop-portal-hyprland
    # UI Engine
    ags gjs gtk3 gtk-layer-shell libnotify
    # Shell tools
    wofi rofi swaync waybar
    # System
    pipewire pipewire-audio wireplumber
    networkmanager nm-connection-editor blueman
    brightnessctl pamixer playerctl
    # Utilities
    jq socat wl-clipboard grim slurp swww
    # Fonts
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
    # Terminal
    kitty
    # File manager
    thunar thunar-archive-plugin
)

AUR_PACKAGES=(
    aylurs-gtk-shell
    catppuccin-gtk-theme-mocha
    bibata-cursor-theme
)

install_pacman() {
    info "Installing pacman packages..."
    sudo pacman -Sy --needed --noconfirm "${PACMAN_PACKAGES[@]}"
    info "Pacman packages installed."
}

install_aur() {
    if command -v yay &>/dev/null; then
        info "Installing AUR packages via yay..."
        yay -S --needed --noconfirm "${AUR_PACKAGES[@]}" || warn "Some AUR packages failed; check manually."
    elif command -v paru &>/dev/null; then
        info "Installing AUR packages via paru..."
        paru -S --needed --noconfirm "${AUR_PACKAGES[@]}" || warn "Some AUR packages failed; check manually."
    else
        warn "No AUR helper found (yay/paru). Install AUR packages manually:"
        printf '  - %s\n' "${AUR_PACKAGES[@]}"
    fi
}

main() {
    if [[ "${DISTRO:-}" == "arch" ]] || command -v pacman &>/dev/null; then
        install_pacman
        install_aur
    else
        warn "Non-Arch system: skipping automated package install."
        echo "Install equivalents for:"
        printf '  %s\n' "${PACMAN_PACKAGES[@]}"
    fi
}

main "$@"
