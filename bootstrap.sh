#!/bin/bash
# =============================================================================
# bootstrap.sh — Phase 5: Hardened Entry Point
# =============================================================================
# Flags:
#   --dry-run       Print what would happen, make no changes
#   --skip-packages Skip package installation
#   --skip-link     Skip config symlinking
#   --skip-init     Skip post-install init
#   --health        Run health check after bootstrap
# =============================================================================

set -uo pipefail

RICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$RICE_DIR/tools/logs"
LOG_FILE="$LOG_DIR/bootstrap.log"
mkdir -p "$LOG_DIR"

# ─── Flags ───────────────────────────────────────────────────────────────────
DRY_RUN=false
SKIP_PACKAGES=false
SKIP_LINK=false
SKIP_INIT=false
RUN_HEALTH=false

for arg in "$@"; do
    case "$arg" in
        --dry-run)       DRY_RUN=true ;;
        --skip-packages) SKIP_PACKAGES=true ;;
        --skip-link)     SKIP_LINK=true ;;
        --skip-init)     SKIP_INIT=true ;;
        --health)        RUN_HEALTH=true ;;
        --help|-h)
            echo "Usage: bootstrap.sh [--dry-run] [--skip-packages] [--skip-link] [--skip-init] [--health]"
            exit 0
            ;;
    esac
done

export DRY_RUN RICE_DIR

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log() {
    local level="$1"; shift
    local msg="$*"
    local ts; ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] [$level] $msg" >> "$LOG_FILE"
    case "$level" in
        INFO)  echo -e "${GREEN}[✓]${RESET} $msg" ;;
        WARN)  echo -e "${YELLOW}[!]${RESET} $msg" ;;
        ERROR) echo -e "${RED}[✗]${RESET} $msg" ;;
        STEP)  echo -e "\n${CYAN}[→]${RESET} ${BOLD}$msg${RESET}" ;;
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
    echo -e "  ${BOLD}Hyprland Desktop UX Framework${RESET}  ${DIM:-}Event-driven • Modular • Animated${RESET}"
    [[ "$DRY_RUN" == "true" ]] && echo -e "  ${YELLOW}${BOLD}DRY-RUN MODE — no changes will be made${RESET}"
    echo ""
}

# ─── Distro detection ────────────────────────────────────────────────────────
detect_distro() {
    log STEP "Detecting distribution..."
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        case "${ID:-}" in
            arch|manjaro|endeavouros|garuda) DISTRO="arch" ;;
            fedora|rhel|centos)              DISTRO="fedora" ;;
            ubuntu|debian|mint|pop)          DISTRO="debian" ;;
            nixos)                           DISTRO="nixos" ;;
            *)                               DISTRO="unknown" ;;
        esac
        log INFO "Detected: ${PRETTY_NAME:-$ID} → DISTRO=$DISTRO"
    else
        DISTRO="unknown"
        log WARN "Could not read /etc/os-release"
    fi
    export DISTRO
}

# ─── Phase runner ────────────────────────────────────────────────────────────
run_phase() {
    local name="$1" script="$2" skip_flag="$3"

    if [[ "$skip_flag" == "true" ]]; then
        log WARN "Skipping phase: $name"
        return 0
    fi

    log STEP "$name"

    if [[ ! -f "$script" ]]; then
        log WARN "Script not found: $script — skipping"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY] Would run: $script"
        return 0
    fi

    bash "$script" || {
        log ERROR "$name FAILED (exit $?). Check: $LOG_FILE"
        echo ""
        echo -e "${RED}${BOLD}Bootstrap halted. Fix the error above and re-run.${RESET}"
        exit 1
    }
    log INFO "$name ✓"
}

# ─── Main ────────────────────────────────────────────────────────────────────
main() {
    banner
    log INFO "Bootstrap started. Log: $LOG_FILE"
    log INFO "Rice directory: $RICE_DIR"

    detect_distro

    run_phase "Package Installation" \
        "$RICE_DIR/scripts/bootstrap/packages.sh"  "$SKIP_PACKAGES"

    run_phase "Config Symlinking" \
        "$RICE_DIR/scripts/bootstrap/link-config.sh" "$SKIP_LINK"

    run_phase "System Initialization" \
        "$RICE_DIR/scripts/bootstrap/init.sh"       "$SKIP_INIT"

    # ── Build CSS ──────────────────────────────────────────────────────
    log STEP "Compiling SCSS → CSS"
    if command -v sass &>/dev/null && [[ "$DRY_RUN" != "true" ]]; then
        bash "$RICE_DIR/tools/dev/build-css.sh" && log INFO "CSS compiled." || \
            log WARN "SCSS compile failed. Run: bash tools/dev/build-css.sh"
    else
        log WARN "sass not found — skipping CSS compile. Run: bash tools/dev/build-css.sh"
    fi

    # ── Optional health check ──────────────────────────────────────────
    if [[ "$RUN_HEALTH" == "true" && "$DRY_RUN" != "true" ]]; then
        log STEP "Running health check..."
        bash "$RICE_DIR/tools/debug/health-check.sh" || true
    fi

    echo ""
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}${BOLD}║  Bootstrap complete! 🌿                   ║${RESET}"
    echo -e "${GREEN}${BOLD}║  Launch Hyprland to start.                ║${RESET}"
    echo -e "${GREEN}${BOLD}║  Hint: run  bash tools/debug/health-check.sh  ║${RESET}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════╝${RESET}"
    echo ""
    log INFO "Bootstrap finished successfully."
}

main "$@"
