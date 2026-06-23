#!/bin/bash
# =============================================================================
# scripts/system/theme-switch.sh — Phase 6: Theme Switcher
# =============================================================================
# Switches between Catppuccin flavors (or any registered theme).
# Updates: GTK, cursor, wallpaper, SCSS variables, AGS hot-reload.
#
# Usage:
#   theme-switch.sh [mocha|latte|frappe|macchiato]
#   theme-switch.sh --list
# =============================================================================

set -uo pipefail

RICE_DIR="${HOME}/.config/makki-rice"
THEMES_DIR="$RICE_DIR/config/themes"
SCSS_VARS="$RICE_DIR/ui-engine/ags/style/variables.scss"
CURRENT_THEME_FILE="${HOME}/.cache/makki-rice/current-theme"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'
info()  { echo -e "${GREEN}[✓]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $*"; }
step()  { echo -e "\n${CYAN}[→]${RESET} ${BOLD}$*${RESET}"; }

mkdir -p "$(dirname "$CURRENT_THEME_FILE")"

# ─── Theme Definitions ────────────────────────────────────────────────────────
# Format: ID | GTK_THEME | ICON_THEME | CURSOR | WALLPAPER_HINT | ACCENT_HEX
declare -A THEMES

THEMES[mocha]="Catppuccin-Mocha-Standard-Blue-Dark|Papirus-Dark|Bibata-Modern-Ice|dark|#89b4fa"
THEMES[latte]="Catppuccin-Latte-Standard-Blue-Light|Papirus|Bibata-Modern-Classic|light|#1e66f5"
THEMES[frappe]="Catppuccin-Frappé-Standard-Blue-Dark|Papirus-Dark|Bibata-Modern-Ice|dark|#8caaee"
THEMES[macchiato]="Catppuccin-Macchiato-Standard-Blue-Dark|Papirus-Dark|Bibata-Modern-Ice|dark|#8aadf4"

list_themes() {
    echo -e "${BOLD}Available themes:${RESET}"
    for id in "${!THEMES[@]}"; do
        local current=""
        [[ "$(cat "$CURRENT_THEME_FILE" 2>/dev/null)" == "$id" ]] && current=" ${GREEN}← active${RESET}"
        echo -e "  ${CYAN}$id${RESET}$current"
    done
}

apply_theme() {
    local id="$1"

    if [[ -z "${THEMES[$id]:-}" ]]; then
        echo "Unknown theme: $id"
        list_themes
        exit 1
    fi

    IFS='|' read -r gtk_theme icon_theme cursor color_scheme accent_hex <<< "${THEMES[$id]}"

    step "Applying theme: $id"

    # ── GTK 3 ─────────────────────────────────────────────────────────
    step "Setting GTK 3 theme..."
    mkdir -p "$HOME/.config/gtk-3.0"
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=$gtk_theme
gtk-icon-theme-name=$icon_theme
gtk-cursor-theme-name=$cursor
gtk-cursor-theme-size=24
gtk-font-name=JetBrains Mono Nerd Font 11
gtk-application-prefer-dark-theme=$([ "$color_scheme" == "dark" ] && echo 1 || echo 0)
EOF
    info "GTK 3 theme: $gtk_theme"

    # ── GTK 4 ─────────────────────────────────────────────────────────
    mkdir -p "$HOME/.config/gtk-4.0"
    cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
    info "GTK 4 theme: $gtk_theme"

    # ── gsettings (if GNOME stack available) ─────────────────────────
    if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-theme "$cursor" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme "prefer-$color_scheme" 2>/dev/null || true
        info "gsettings updated"
    fi

    # ── Cursor ────────────────────────────────────────────────────────
    mkdir -p "$HOME/.icons/default"
    cat > "$HOME/.icons/default/index.theme" << EOF
[Icon Theme]
Name=Default
Comment=Default cursor
Inherits=$cursor
EOF
    info "Cursor theme: $cursor"

    # ── Wallpaper ─────────────────────────────────────────────────────
    local wp="$RICE_DIR/assets/wallpapers/${id}.jpg"
    if [[ -f "$wp" ]] && command -v swww &>/dev/null; then
        step "Transitioning wallpaper..."
        swww img "$wp" \
            --transition-type grow \
            --transition-pos 0.5,0.5 \
            --transition-duration 1.2 \
            2>/dev/null && info "Wallpaper: $wp" || warn "swww not running"
    else
        [[ ! -f "$wp" ]] && warn "No wallpaper found for $id at $wp"
    fi

    # ── Hyprland border color ─────────────────────────────────────────
    if command -v hyprctl &>/dev/null; then
        # Convert hex to Hyprland RGBA
        local r g b
        r=$(( 16#${accent_hex:1:2} ))
        g=$(( 16#${accent_hex:3:2} ))
        b=$(( 16#${accent_hex:5:2} ))
        local rgba
        rgba=$(printf "rgba(%d, %d, %d, 1.0)" "$r" "$g" "$b")
        hyprctl keyword general:col.active_border "${accent_hex}ff ${accent_hex}aa 45deg" 2>/dev/null || true
        info "Hyprland border: $accent_hex"
    fi

    # ── Rebuild AGS CSS ───────────────────────────────────────────────
    step "Rebuilding CSS for $id..."
    if command -v sass &>/dev/null; then
        bash "$RICE_DIR/tools/dev/build-css.sh" 2>/dev/null && \
            info "CSS rebuilt." || warn "CSS rebuild failed"
    fi

    # ── Hot-reload AGS ────────────────────────────────────────────────
    if pgrep -x ags &>/dev/null; then
        ags -r "App.resetCss(); App.applyCss(App.configDir + '/style/main.css')" 2>/dev/null && \
            info "AGS hot-reloaded." || warn "AGS reload failed"
    fi

    # ── Persist current theme ─────────────────────────────────────────
    echo "$id" > "$CURRENT_THEME_FILE"

    echo ""
    info "Theme switched to: ${BOLD}$id${RESET}"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
case "${1:---list}" in
    --list|-l)  list_themes ;;
    --current)  cat "$CURRENT_THEME_FILE" 2>/dev/null || echo "none" ;;
    mocha|latte|frappe|macchiato) apply_theme "$1" ;;
    *)
        echo "Usage: theme-switch.sh [mocha|latte|frappe|macchiato|--list|--current]"
        exit 1
        ;;
esac
