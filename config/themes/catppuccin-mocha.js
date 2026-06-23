// =============================================================================
// config/themes/catppuccin-mocha.js — Theme: Catppuccin Mocha
// =============================================================================
// Single source of truth for this flavour. Used by the theme switcher.
// =============================================================================

export const meta = {
    name:        "Catppuccin Mocha",
    id:          "catppuccin-mocha",
    variant:     "dark",
    gtkTheme:    "Catppuccin-Mocha-Standard-Blue-Dark",
    iconTheme:   "Papirus-Dark",
    cursorTheme: "Bibata-Modern-Ice",
    wallpaper:   "~/.config/makki-rice/assets/wallpapers/default.jpg",
};

export const colors = {
    rosewater: "#f5e0dc", flamingo: "#f2cdcd", pink: "#f5c2e7",
    mauve:     "#cba6f7", red:      "#f38ba8", maroon: "#eba0ac",
    peach:     "#fab387", yellow:   "#f9e2af", green:  "#a6e3a1",
    teal:      "#94e2d5", sky:      "#89dceb", sapphire: "#74c7ec",
    blue:      "#89b4fa", lavender: "#b4befe",
    text:      "#cdd6f4", subtext1: "#bac2de", subtext0: "#a6adc8",
    overlay2:  "#9399b2", overlay1: "#7f849c", overlay0: "#6c7086",
    surface2:  "#585b70", surface1: "#45475a", surface0: "#313244",
    base:      "#1e1e2e", mantle:   "#181825", crust:   "#11111b",
};

export const accents = {
    primary:   colors.blue,
    secondary: colors.mauve,
    tertiary:  colors.green,
    warning:   colors.peach,
    error:     colors.red,
    success:   colors.green,
};

export default { meta, colors, accents };
