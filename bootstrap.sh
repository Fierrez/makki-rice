#!/bin/bash
# =============================================================================
# bootstrap.sh — Hypr OS Rice Entry Point
# =============================================================================
# This is the primary entry point for setting up the entire rice.
# Run once after cloning. Safe to re-run (idempotent).
# =============================================================================

set -euo pipefail

RICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$RICE_DIR/tools/logs/bootstrap.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Ensure log directory exists
mkdir -p "$RICE_DIR/tools/logs"

log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $msg" >> "$LOG_FILE"

    case "$level" in
        INFO)  echo -e "${GREEN}[✓]${RESET} $msg" ;;
        WARN)  echo -e "${YELLOW}[!]${RESET} $msg" ;;
        ERROR) echo -e "${RED}[✗]${RESET} $msg" ;;
        STEP)  echo -e "${CYAN}[→]${RESET} ${BOLD}$msg${RESET}" ;;
    esac
}

banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
  ███╗   ███╗ █████╗ ██╗  ██╗██╗  ██╗██╗    ██████╗ ██╗ ██████╗███████╗
  ████╗ ████║██╔══██╗██║ ██╔╝██║ ██╔╝██║    ██╔══██╗██║██╔════╝██╔════╝
  ██╔████╔██║███████║█████╔╝ █████╔╝ ██║    ██████╔╝██║██║     █████╗
  ██║╚██╔╝██║██╔══██║██╔═██╗ ██╔═██╗ ██║    ██╔══██╗██║██║     ██╔══╝
  ██║ ╚═╝ ██║██║  ██║██║  ██╗██║  ██╗██║    ██║  ██║██║╚██████╗███████╗
  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝    ╚═╝  ╚═╝╚═╝ ╚═════╝╚══════╝
EOF
    echo -e "${RESET}"
    echo -e "  ${BOLD}Hyprland Desktop UX Framework${RESET} — Event-driven • Modular • Animated"
    echo ""
}

check_distro() {
    log STEP "Detecting distribution..."
    if command -v pacman &>/dev/null; then
        log INFO "Arch Linux detected. Proceeding with pacman."
        DISTRO="arch"
    elif command -v apt &>/dev/null; then
        log WARN "Debian/Ubuntu detected. Some packages may need manual setup."
        DISTRO="debian"
    elif command -v dnf &>/dev/null; then
        log WARN "Fedora detected. Some packages may need manual setup."
        DISTRO="fedora"
    else
        log ERROR "Unsupported distribution. Please install dependencies manually."
        DISTRO="unknown"
    fi
}

run_phase() {
    local phase_name="$1"
    local script="$2"

    log STEP "Phase: $phase_name"

    if [[ -f "$script" ]]; then
        bash "$script" || {
            log ERROR "$phase_name failed. Check $LOG_FILE for details."
            exit 1
        }
        log INFO "$phase_name completed."
    else
        log WARN "Script not found: $script — skipping."
    fi
}

main() {
    banner

    log INFO "Bootstrap started. Log: $LOG_FILE"
    log INFO "Rice directory: $RICE_DIR"

    check_distro
    export RICE_DIR DISTRO

    run_phase "Package Installation"      "$RICE_DIR/scripts/bootstrap/packages.sh"
    run_phase "Config Symlinking"         "$RICE_DIR/scripts/bootstrap/link-config.sh"
    run_phase "System Initialization"     "$RICE_DIR/scripts/bootstrap/init.sh"

    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}${BOLD}║   Rice bootstrap complete! 🌿         ║${RESET}"
    echo -e "${GREEN}${BOLD}║   Launch Hyprland to begin.           ║${RESET}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════╝${RESET}"
    echo ""
    log INFO "Bootstrap finished successfully."
}

main "$@"
