#!/usr/bin/env bash
# =============================================================================
# scripts/lib/ags-compat.sh — AGS Binary Resolver
# =============================================================================
# Sources this file to get AGS_BIN, ags_run(), and ags_pgrep().
#
# Priority: ags (aylurs-gtk-shell, official) → agsv1 (legacy fallback)
# Install:  yay -S aylurs-gtk-shell
# Docs:     aylur.github.io/ags-docs
# =============================================================================

if command -v ags &>/dev/null; then
    AGS_BIN="ags"
elif command -v agsv1 &>/dev/null; then
    AGS_BIN="agsv1"
else
    AGS_BIN=""
fi

# ags_run <js>
# Fire-and-forget JS evaluation in the running AGS context. Never fails.
ags_run() {
    [[ -z "$AGS_BIN" ]] && return 0
    "$AGS_BIN" -r "$1" 2>/dev/null || true
}

# ags_run_blocking <js>
# Like ags_run but captures stderr (for debug tools).
ags_run_blocking() {
    [[ -z "$AGS_BIN" ]] && { echo "AGS not installed."; return 1; }
    "$AGS_BIN" -r "$1" 2>&1 || echo "AGS not running or eval failed."
}

# ags_pgrep
# Returns true (0) if AGS daemon is running, false (1) otherwise.
ags_pgrep() {
    pgrep -x ags &>/dev/null || pgrep -x agsv1 &>/dev/null
}
