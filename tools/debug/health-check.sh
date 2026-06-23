#!/bin/bash
# =============================================================================
# tools/debug/health-check.sh — Rice Health Check
# =============================================================================
# Verifies all components are installed and running correctly.
# Run after bootstrap or to diagnose issues.
# =============================================================================

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

PASS=0; FAIL=0; WARN=0

pass() { echo -e "  ${GREEN}✓${RESET} $*"; (( PASS++ )); }
fail() { echo -e "  ${RED}✗${RESET} $*"; (( FAIL++ )); }
warn() { echo -e "  ${YELLOW}!${RESET} $*"; (( WARN++ )); }
section() { echo -e "\n${CYAN}${BOLD}$*${RESET}"; echo "  ────────────────────────────"; }

check_cmd() {
    local cmd="$1" label="${2:-$1}"
    command -v "$cmd" &>/dev/null && pass "$label installed" || fail "$label NOT FOUND"
}

check_service() {
    local svc="$1"
    systemctl --user is-active "$svc" &>/dev/null && \
        pass "systemd: $svc running" || \
        warn "systemd: $svc not active"
}

check_symlink() {
    local path="$1" label="$2"
    [[ -L "$path" ]] && pass "Symlink: $label" || \
    [[ -e "$path" ]] && warn "$label exists but is NOT a symlink" || \
    fail "$label missing ($path)"
}

check_file() {
    local path="$1" label="$2"
    [[ -f "$path" ]] && pass "$label" || fail "$label missing"
}

check_socket() {
    local sock="$1" label="$2"
    [[ -S "$sock" ]] && pass "$label socket active" || warn "$label socket not found"
}

# ─── Header ──────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════╗"
echo "  ║    makki-rice Health Check       ║"
echo "  ╚══════════════════════════════════╝"
echo -e "${RESET}"

# ─── Core Dependencies ───────────────────────────────────────────────────────
section "Core Dependencies"
check_cmd hyprland   "Hyprland"
check_cmd ags        "AGS"
check_cmd swaync     "swaync"
check_cmd wofi       "wofi"
check_cmd socat      "socat"
check_cmd jq         "jq"
check_cmd swww       "swww"
check_cmd brightnessctl "brightnessctl"
check_cmd pamixer    "pamixer"
check_cmd playerctl  "playerctl"
check_cmd grim       "grim"
check_cmd slurp      "slurp"
check_cmd sass       "sass (SCSS compiler)" || warn "Install: npm i -g sass  OR  pacman -S dart-sass"

# ─── Config Symlinks ─────────────────────────────────────────────────────────
section "Config Symlinks"
check_symlink "$HOME/.config/hypr"      "hypr config"
check_symlink "$HOME/.config/ags"       "AGS config"
check_symlink "$HOME/.config/wofi"      "wofi config"
check_symlink "$HOME/.config/rofi"      "rofi config"
check_symlink "$HOME/.config/swaync"    "swaync config"
check_symlink "$HOME/.config/makki-rice" "rice self-reference"

# ─── Key Config Files ────────────────────────────────────────────────────────
section "Key Config Files"
check_file "$HOME/.config/hypr/hyprland.conf"   "hyprland.conf"
check_file "$HOME/.config/ags/config.js"        "ags/config.js"
check_file "$HOME/.config/ags/style/main.css"   "ags/style/main.css (compiled)" || \
    warn "Run: bash tools/dev/build-css.sh"

# ─── Running Processes ───────────────────────────────────────────────────────
section "Running Processes"
pgrep -x Hyprland &>/dev/null && pass "Hyprland running" || warn "Hyprland not running"
pgrep -x ags      &>/dev/null && pass "AGS running"      || warn "AGS not running"
pgrep -x swaync   &>/dev/null && pass "swaync running"   || warn "swaync not running"
pgrep -x swww-daemon &>/dev/null && pass "swww daemon running" || warn "swww-daemon not running"

# ─── Hyprland Socket ─────────────────────────────────────────────────────────
section "Hyprland IPC"
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
    check_socket "$SOCK" "socket2"
    pass "HYPRLAND_INSTANCE_SIGNATURE set: $HYPRLAND_INSTANCE_SIGNATURE"
else
    warn "HYPRLAND_INSTANCE_SIGNATURE not set — Hyprland may not be running"
fi

# ─── Hyprland Config Errors ───────────────────────────────────────────────────
section "Hyprland Config Errors"
if command -v hyprctl &>/dev/null; then
    errors=$(hyprctl -j configerrors 2>/dev/null)
    has_json=false
    if [[ $? -eq 0 && -n "$errors" ]]; then
        has_json=true
    fi

    if [[ "$has_json" == "true" ]]; then
        if command -v jq &>/dev/null; then
            count=$(echo "$errors" | jq 'length' 2>/dev/null || echo 0)
        else
            count=$(echo "$errors" | grep -c '"error"' || echo 0)
        fi
    else
        raw_errors=$(hyprctl configerrors 2>/dev/null)
        if [[ "$raw_errors" == "no errors found" || -z "$raw_errors" ]]; then
            count=0
        else
            count=$(echo "$raw_errors" | grep -c '^' || echo 0)
        fi
    fi

    # Sanitize count to ensure it is a clean integer (stripping carriage returns/spaces)
    count=$(echo "$count" | tr -cd '0-9')
    count=${count:-0}

    if (( count > 0 )); then
        warn "$count configuration error(s) detected. Check: ~/.local/share/makki-rice/logs/hyprland-config-errors.log"
    else
        pass "No configuration errors detected"
    fi
else
    warn "hyprctl not found — cannot check config errors"
fi

# ─── Services ────────────────────────────────────────────────────────────────
section "Systemd User Services"
check_service "hypr-rice.service"

# ─── Event Router ────────────────────────────────────────────────────────────
section "Event Router"
LOG="${HOME}/.local/share/makki-rice/logs/event-router.log"
if [[ -f "$LOG" ]]; then
    local_size=$(stat -c%s "$LOG" 2>/dev/null || echo 0)
    local_age=$(( $(date +%s) - $(stat -c%Y "$LOG" 2>/dev/null || echo 0) ))
    pass "Log exists (${local_size} bytes, ${local_age}s ago)"
    if (( local_age > 60 )); then
        warn "Log not updated in >60s — router may be stopped"
    fi
else
    warn "No event router log found"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "──────────────────────────────────────────"
echo -e "  ${GREEN}✓ PASS: $PASS${RESET}  ${RED}✗ FAIL: $FAIL${RESET}  ${YELLOW}! WARN: $WARN${RESET}"
echo ""

if (( FAIL > 0 )); then
    echo -e "  ${RED}${BOLD}Issues found. Run: bash bootstrap.sh${RESET}"
    exit 1
else
    echo -e "  ${GREEN}${BOLD}All critical checks passed.${RESET}"
fi
