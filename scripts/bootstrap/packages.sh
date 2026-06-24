#!/bin/bash
# =============================================================================
# scripts/bootstrap/packages.sh — Phase 5: Hardened Package Installer
# =============================================================================
# Supports: Arch (pacman + AUR), Fedora (dnf), Debian/Ubuntu (apt)
# Features: dry-run mode, skip-installed, rollback list generation
# =============================================================================

set -uo pipefail

RICE_DIR="${RICE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
DRY_RUN="${DRY_RUN:-false}"
ROLLBACK_FILE="${RICE_DIR}/tools/logs/installed-packages.txt"

mkdir -p "$(dirname "$ROLLBACK_FILE")"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'
info() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
error(){ echo -e "${RED}[✗]${RESET} $*"; }
dry() { echo -e "  [DRY] $*"; }

# ─── Package Lists ────────────────────────────────────────────────────────────

ARCH_CORE=(
    hyprland hyprpaper hyprpicker hypridle hyprlock
    xdg-desktop-portal-hyprland xdg-desktop-portal
)

ARCH_UI=(
    gjs gtk3 gtk-layer-shell libnotify
    wofi rofi swaync
    awww
)

ARCH_SYSTEM=(
    pipewire pipewire-audio wireplumber
    networkmanager nm-connection-editor
    blueman bluez bluez-utils
    brightnessctl pamixer playerctl
    polkit-gnome
)

ARCH_UTILS=(
    jq socat wl-clipboard grim slurp
    cliphist
    kitty thunar thunar-archive-plugin
    dart-sass
)

ARCH_FONTS=(
    ttf-jetbrains-mono-nerd
    noto-fonts noto-fonts-emoji
    ttf-font-awesome
)

AUR_PACKAGES=(
    aylurs-gtk-shell
    catppuccin-gtk-theme-mocha
    bibata-cursor-theme
    papirus-icon-theme
    spotify-launcher
)

# Fedora equivalents (best-effort)
FEDORA_PACKAGES=(
    hyprland wl-copy grim slurp
    kitty thunar jq socat
    brightnessctl pamixer
    noto-fonts jetbrains-mono-fonts
)

# Debian/Ubuntu equivalents (best-effort)
DEBIAN_PACKAGES=(
    kitty thunar jq socat
    brightnessctl playerctl
    fonts-noto fonts-jetbrains-mono
    wl-clipboard grim slurp
)

# ─── Helpers ──────────────────────────────────────────────────────────────────

pkg_installed_arch() {
    pacman -Q "$1" &>/dev/null
}

record_installed() {
    echo "$1" >> "$ROLLBACK_FILE"
}

pacman_install() {
    local pkgs=("$@")
    local to_install=()

    for pkg in "${pkgs[@]}"; do
        if pkg_installed_arch "$pkg"; then
            info "$pkg already installed — skip"
        else
            to_install+=("$pkg")
        fi
    done

    [[ ${#to_install[@]} -eq 0 ]] && return 0

    if [[ "$DRY_RUN" == "true" ]]; then
        dry "pacman -S ${to_install[*]}"
        return 0
    fi

    sudo pacman -S --needed --noconfirm "${to_install[@]}" && \
        printf '%s\n' "${to_install[@]}" >> "$ROLLBACK_FILE"
}

aur_install() {
    local helper=""
    command -v yay  &>/dev/null && helper="yay"
    command -v paru &>/dev/null && helper="paru"

    if [[ -z "$helper" ]]; then
        warn "No AUR helper (yay/paru). Skipping AUR packages:"
        printf '  - %s\n' "$@"
        return 0
    fi

    local to_install=()
    for pkg in "$@"; do
        pkg_installed_arch "$pkg" || to_install+=("$pkg")
    done

    [[ ${#to_install[@]} -eq 0 ]] && return 0

    if [[ "$DRY_RUN" == "true" ]]; then
        dry "$helper -S ${to_install[*]}"
        return 0
    fi

    "$helper" -S --needed --noconfirm "${to_install[@]}" 2>/dev/null || \
        warn "Some AUR packages failed — install manually: ${to_install[*]}"
}

dnf_install() {
    if [[ "$DRY_RUN" == "true" ]]; then
        dry "dnf install ${*}"
        return 0
    fi
    sudo dnf install -y "$@" 2>/dev/null || warn "Some dnf packages failed"
}

apt_install() {
    if [[ "$DRY_RUN" == "true" ]]; then
        dry "apt install ${*}"
        return 0
    fi
    sudo apt install -y "$@" 2>/dev/null || warn "Some apt packages failed"
}

# ─── Distro-specific install ──────────────────────────────────────────────────

install_arch() {
    info "Installing Arch packages..."

    pacman_install "${ARCH_CORE[@]}"
    pacman_install "${ARCH_UI[@]}"
    pacman_install "${ARCH_SYSTEM[@]}"
    pacman_install "${ARCH_UTILS[@]}"
    pacman_install "${ARCH_FONTS[@]}"

    info "Installing AUR packages..."
    aur_install "${AUR_PACKAGES[@]}"

    info "Arch installation complete."
}

install_fedora() {
    warn "Fedora support is best-effort. Some packages may differ."
    info "Installing Fedora packages..."
    dnf_install "${FEDORA_PACKAGES[@]}"
    warn "Install hyprland manually for Fedora: https://copr.fedorainfracloud.org/coprs/solopasha/hyprland/"
}

install_debian() {
    warn "Debian/Ubuntu support is best-effort."
    info "Updating package list..."
    [[ "$DRY_RUN" != "true" ]] && sudo apt update -q
    apt_install "${DEBIAN_PACKAGES[@]}"
    warn "Install hyprland manually: https://github.com/hyprwm/Hyprland/wiki/Installation"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    [[ "$DRY_RUN" == "true" ]] && warn "DRY-RUN mode — no changes will be made"

    local distro="${DISTRO:-}"
    if [[ -z "$distro" ]]; then
        command -v pacman &>/dev/null && distro="arch"
        command -v dnf    &>/dev/null && distro="fedora"
        command -v apt    &>/dev/null && distro="debian"
    fi

    case "$distro" in
        arch)   install_arch   ;;
        fedora) install_fedora ;;
        debian|ubuntu) install_debian ;;
        *)
            error "Unrecognized distro. Set DISTRO=arch|fedora|debian or install manually."
            exit 1
            ;;
    esac

    info "Package phase done. Rollback list: $ROLLBACK_FILE"
}

main "$@"
