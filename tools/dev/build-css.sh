#!/bin/bash
# =============================================================================
# tools/dev/build-css.sh — SCSS Compiler + AGS Hot-Reload (Updated)
# =============================================================================
# Usage:
#   build-css.sh               # compile once
#   build-css.sh --watch       # watch for changes and auto-rebuild
#   build-css.sh --theme mocha # switch theme then compile
# =============================================================================

set -uo pipefail

RICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCSS_IN="$RICE_DIR/ui-engine/ags/style/main.scss"
CSS_OUT="$RICE_DIR/ui-engine/ags/style/main.css"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'
info() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
step() { echo -e "${CYAN}[→]${RESET} ${BOLD}$*${RESET}"; }

# ─── Check deps ──────────────────────────────────────────────────────────────
check_sass() {
    command -v sass &>/dev/null && return 0
    echo -e "${YELLOW}sass not found.${RESET}"
    echo "Install with:  npm i -g sass   OR   sudo pacman -S dart-sass"
    exit 1
}

# ─── Compile ─────────────────────────────────────────────────────────────────
compile() {
    step "Compiling SCSS → CSS..."
    sass --no-source-map --style=compressed "$SCSS_IN" "$CSS_OUT" 2>&1

    if [[ $? -eq 0 ]]; then
        local size
        size=$(stat -c%s "$CSS_OUT" 2>/dev/null || echo "?")
        info "CSS written: $CSS_OUT (${size} bytes)"
        ags_reload
    else
        warn "SCSS compilation FAILED"
        return 1
    fi
}

# ─── AGS hot-reload ──────────────────────────────────────────────────────────
ags_reload() {
    if pgrep -x ags &>/dev/null; then
        ags -r "App.resetCss?.(); App.applyCss?.(App.configDir + '/style/main.css')" 2>/dev/null && \
            info "AGS hot-reloaded." || warn "AGS reload failed (non-fatal)"
    fi
}

# ─── Generate theme vars first ───────────────────────────────────────────────
gen_vars() {
    local theme="${1:-}"
    if command -v node &>/dev/null; then
        local args=""
        [[ -n "$theme" ]] && args="$theme"
        node "$RICE_DIR/tools/dev/gen-theme-vars.mjs" $args 2>/dev/null && \
            info "Theme variables generated." || warn "Theme var generation failed (using existing variables.scss)"
    else
        warn "node not found — skipping variables.scss generation"
    fi
}

# ─── Watch mode ──────────────────────────────────────────────────────────────
watch_mode() {
    step "Watch mode — monitoring SCSS files..."
    echo "Press Ctrl+C to stop."

    if command -v inotifywait &>/dev/null; then
        # inotify-based (Linux)
        while inotifywait -q -e modify,create "$RICE_DIR/ui-engine/ags/style/"*.scss 2>/dev/null; do
            echo ""
            compile
        done
    else
        # Fallback: poll every 2s
        warn "inotifywait not found — using 2s poll (install inotify-tools for better performance)"
        local last_hash=""
        while true; do
            current_hash=$(find "$RICE_DIR/ui-engine/ags/style" -name "*.scss" -exec md5sum {} \; 2>/dev/null | md5sum)
            if [[ "$current_hash" != "$last_hash" ]]; then
                last_hash="$current_hash"
                [[ -n "$last_hash" ]] && compile
            fi
            sleep 2
        done
    fi
}

# ─── Main ────────────────────────────────────────────────────────────────────
check_sass

THEME_ARG=""
DO_WATCH=false

for arg in "$@"; do
    case "$arg" in
        --watch|-w)     DO_WATCH=true ;;
        --theme)        shift; THEME_ARG="${1:-}" ;;
        mocha|latte|frappe|macchiato) THEME_ARG="$arg" ;;
    esac
done

gen_vars "$THEME_ARG"
compile

if [[ "$DO_WATCH" == "true" ]]; then
    watch_mode
fi
