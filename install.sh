#!/bin/bash
# =============================================================================
# install.sh — Full Installation Script
# =============================================================================
# Handles: dependency install, config copy, permissions, systemd services
# =============================================================================

set -euo pipefail

RICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_TARGET="$HOME/.config"

FORCE_OVERWRITE="${FORCE_OVERWRITE:-false}"
HW_MODE=""
for arg in "$@"; do
    case "$arg" in
        --force|--overwrite) FORCE_OVERWRITE=true ;;
        --nvidia|--vm|--intel-amd|--intel|--amd|--auto) HW_MODE="$arg" ;;
    esac
done

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()  { echo -e "${GREEN}[✓]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $*"; }
error() { echo -e "${RED}[✗]${RESET} $*"; exit 1; }
step()  { echo -e "\n${CYAN}[→]${RESET} ${BOLD}$*${RESET}"; }

# ─── Dependency Detection ───────────────────────────────────────────────────

ARCH_PACKAGES=(
    hyprland hypridle hyprlock
    xdg-desktop-portal-hyprland xdg-desktop-portal
    wofi rofi swaync
    gjs gtk3 gtk-layer-shell
    pipewire pipewire-pulse pipewire-alsa wireplumber
    networkmanager nm-connection-editor
    blueman bluez bluez-utils
    brightnessctl pamixer playerctl
    polkit-gnome
    jq socat wl-clipboard grim slurp
    cliphist
    kitty thunar thunar-archive-plugin
    dart-sass
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji ttf-font-awesome
    awww
    bun
)

install_arch() {
    step "Installing packages via pacman..."
    sudo pacman -Sy --needed --noconfirm "${ARCH_PACKAGES[@]}" 2>/dev/null || true

    # Install AGS (aylurs-gtk-shell-git) via AUR helper
    local helper=""
    command -v yay  &>/dev/null && helper="yay"
    command -v paru &>/dev/null && helper="paru"

    if command -v ags &>/dev/null; then
        info "ags (aylurs-gtk-shell-git) already installed — skip"
    elif [[ -n "$helper" ]]; then
        info "Installing aylurs-gtk-shell-git via $helper..."
        "$helper" -S --needed --noconfirm aylurs-gtk-shell-git 2>/dev/null || \
            warn "aylurs-gtk-shell-git install failed — install manually: yay -S aylurs-gtk-shell-git"
    else
        warn "No AUR helper found. Install AGS manually: yay -S aylurs-gtk-shell-git"
        warn "See: https://aylur.github.io/ags/guide/install.html"
    fi
}

# ─── Config Linking ──────────────────────────────────────────────────────────

link_config() {
    step "Linking configs to ~/.config..."

    declare -A LINKS=(
        ["hypr"]="$CONFIG_TARGET/hypr"
        ["waybar"]="$CONFIG_TARGET/waybar"
        ["wofi"]="$CONFIG_TARGET/wofi"
        ["rofi"]="$CONFIG_TARGET/rofi"
        ["swaync"]="$CONFIG_TARGET/swaync"
    )

    for src_name in "${!LINKS[@]}"; do
        local src="$RICE_DIR/config/$src_name"
        local dst="${LINKS[$src_name]}"

        if [[ -d "$src" ]]; then
            if [[ -L "$dst" ]]; then
                info "Already linked: $dst"
            elif [[ -d "$dst" ]]; then
                if [[ "$FORCE_OVERWRITE" == "true" ]]; then
                    info "Overwriting: $dst"
                    rm -rf "$dst"
                else
                    warn "Backing up existing: $dst → $dst.bak"
                    mv "$dst" "$dst.bak"
                fi
                ln -sf "$src" "$dst"
                info "Linked: $src → $dst"
            else
                ln -sf "$src" "$dst"
                info "Linked: $src → $dst"
            fi
        else
            warn "Source not found: $src — skipping."
        fi
    done

    # AGS config
    local ags_src="$RICE_DIR/ui-engine/ags"
    local ags_dst="$CONFIG_TARGET/ags"
    if [[ -d "$ags_src" ]]; then
        if [[ -d "$ags_dst" && ! -L "$ags_dst" ]]; then
            if [[ "$FORCE_OVERWRITE" == "true" ]]; then
                info "Overwriting AGS config: $ags_dst"
                rm -rf "$ags_dst"
            else
                warn "Backing up AGS config: $ags_dst → $ags_dst.bak"
                mv "$ags_dst" "$ags_dst.bak"
            fi
        fi
        ln -sf "$ags_src" "$ags_dst"
        info "Linked AGS: $ags_src → $ags_dst"
    fi
}

# ─── Permissions ─────────────────────────────────────────────────────────────

set_permissions() {
    step "Setting script permissions..."
    find "$RICE_DIR/scripts" -name "*.sh" -exec chmod +x {} \;
    find "$RICE_DIR/services" -name "*.sh" -exec chmod +x {} \;
    chmod +x "$RICE_DIR/bootstrap.sh" "$RICE_DIR/install.sh" "$RICE_DIR/uninstall.sh"
    info "Permissions set."
}

# ─── Systemd Services ─────────────────────────────────────────────────────────

install_services() {
    step "Installing systemd user services..."

    local service_src="$RICE_DIR/services/systemd/hypr-rice.service"
    local service_dst="$HOME/.config/systemd/user/hypr-rice.service"

    if [[ -f "$service_src" ]]; then
        mkdir -p "$(dirname "$service_dst")"
        cp "$service_src" "$service_dst"
        systemctl --user daemon-reload
        systemctl --user enable hypr-rice.service
        info "Service installed and enabled: hypr-rice.service"
    else
        warn "Service file not found — skipping."
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo -e "${BOLD}${CYAN}Makki Rice Installer${RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if command -v pacman &>/dev/null; then
        install_arch
    else
        warn "Non-Arch system. Skipping package install. Install deps manually."
    fi

    link_config
    set_permissions

    # Generate initial hardware configuration
    if [[ -f "$RICE_DIR/scripts/system/detect-hw.sh" ]]; then
        step "Detecting hardware & VM environment..."
        bash "$RICE_DIR/scripts/system/detect-hw.sh" $HW_MODE
    fi

    install_services

    echo ""
    info "Installation complete. Log in to a Hyprland session to start."
}

main "$@"
