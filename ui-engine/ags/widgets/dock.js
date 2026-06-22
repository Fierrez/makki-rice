// =============================================================================
// dock.js — Floating App Dock
// =============================================================================
// A floating bottom dock with autohide and app launching.
// Magnification on hover (macOS-style).
// =============================================================================

import { Widget, Utils, App } from "resource:///com/github/Aylur/ags/imports.js";

const { Box, Button, Icon, Window, EventBox, Revealer } = Widget;
const { execAsync } = Utils;

// ─── Pinned Apps ─────────────────────────────────────────────────────────────
const PINNED_APPS = [
    { icon: "firefox",           cmd: "firefox",           label: "Firefox"    },
    { icon: "thunar",            cmd: "thunar",            label: "Files"      },
    { icon: "kitty",             cmd: "kitty",             label: "Terminal"   },
    { icon: "code",              cmd: "code",              label: "VSCode"     },
    { icon: "discord",           cmd: "discord",           label: "Discord"    },
    { icon: "spotify",           cmd: "spotify-launcher",  label: "Spotify"    },
    { icon: "telegram",          cmd: "telegram-desktop",  label: "Telegram"   },
    { icon: "system-settings",   cmd: "gnome-control-center", label: "Settings" },
];

// ─── Dock Item ────────────────────────────────────────────────────────────────
const DockItem = ({ icon, cmd, label }) => {
    const btn = Button({
        className: "dock-item",
        tooltip_text: label,
        child: Icon({
            icon,
            size: 32,
        }),
        onClicked: () => execAsync(cmd).catch(console.error),
    });

    // Hover scale effect
    btn.connect("enter-notify-event", () => {
        btn.toggleClassName("hovered", true);
    });
    btn.connect("leave-notify-event", () => {
        btn.toggleClassName("hovered", false);
    });

    return btn;
};

// ─── Separator ────────────────────────────────────────────────────────────────
const DockSeparator = () => Box({ className: "dock-separator" });

// ─── Dock Container ───────────────────────────────────────────────────────────
const DockContainer = () => {
    const visible = Variable(true);
    let hideTimeout = null;

    const dock = Box({
        className: "dock",
        children: [
            ...PINNED_APPS.map(DockItem),
        ],
    });

    const revealer = Revealer({
        transition: "slide_up",
        transitionDuration: 250,
        revealChild: true,
        child: dock,
    });

    // Auto-hide on idle (optional — can disable)
    // interval(5000, () => {
    //     revealer.revealChild = false;
    // });

    return Box({
        name: "dock-wrapper",
        child: revealer,
    });
};

// ─── Window ───────────────────────────────────────────────────────────────────
export default () => Window({
    name: "dock",
    className: "dock-window",
    anchor: ["bottom"],
    exclusivity: "normal",
    layer: "top",
    margins: [0, 0, 12, 0],
    child: DockContainer(),
});
