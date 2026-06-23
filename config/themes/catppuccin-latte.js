// config/themes/catppuccin-latte.js — Theme: Catppuccin Latte (Light)

export const meta = {
    name:        "Catppuccin Latte",
    id:          "catppuccin-latte",
    variant:     "light",
    gtkTheme:    "Catppuccin-Latte-Standard-Blue-Light",
    iconTheme:   "Papirus",
    cursorTheme: "Bibata-Modern-Classic",
    wallpaper:   "~/.config/makki-rice/assets/wallpapers/latte.jpg",
};

export const colors = {
    rosewater: "#dc8a78", flamingo: "#dd7878", pink: "#ea76cb",
    mauve:     "#8839ef", red:      "#d20f39", maroon: "#e64553",
    peach:     "#fe640b", yellow:   "#df8e1d", green:  "#40a02b",
    teal:      "#179299", sky:      "#04a5e5", sapphire: "#209fb5",
    blue:      "#1e66f5", lavender: "#7287fd",
    text:      "#4c4f69", subtext1: "#5c5f77", subtext0: "#6c6f85",
    overlay2:  "#7c7f93", overlay1: "#8c8fa1", overlay0: "#9ca0b0",
    surface2:  "#acb0be", surface1: "#bcc0cc", surface0: "#ccd0da",
    base:      "#eff1f5", mantle:   "#e6e9ef", crust:   "#dce0e8",
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
