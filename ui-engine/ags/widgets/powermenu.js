// =============================================================================
// widgets/powermenu.js — Power Menu
// =============================================================================
// Centered overlay with: Lock, Sleep, Reboot, Shutdown, Logout.
// Triggered by keybind (SUPER+SHIFT+Q or SUPER+Power).
// Blur overlay + keyboard navigation.
// =============================================================================

import { Widget, Utils, App, Variable } from "resource:///com/github/Aylur/ags/imports.js";

const { Box, Button, Label, Window, Revealer, Icon, EventBox } = Widget;
const { execAsync } = Utils;

// ─── Actions ─────────────────────────────────────────────────────────────────
const ACTIONS = [
    {
        id:      "lock",
        label:   "Lock",
        icon:    "system-lock-screen-symbolic",
        cmd:     "loginctl lock-session",
        color:   "blue",
    },
    {
        id:      "sleep",
        label:   "Sleep",
        icon:    "weather-clear-night-symbolic",
        cmd:     "systemctl suspend",
        color:   "teal",
    },
    {
        id:      "logout",
        label:   "Logout",
        icon:    "system-log-out-symbolic",
        cmd:     "hyprctl dispatch exit",
        color:   "mauve",
        confirm: true,
    },
    {
        id:      "reboot",
        label:   "Reboot",
        icon:    "system-reboot-symbolic",
        cmd:     "systemctl reboot",
        color:   "peach",
        confirm: true,
    },
    {
        id:      "shutdown",
        label:   "Shutdown",
        icon:    "system-shutdown-symbolic",
        cmd:     "systemctl poweroff",
        color:   "red",
        confirm: true,
    },
];

// ─── State ───────────────────────────────────────────────────────────────────
const confirming = Variable(null);  // null | action id

// ─── Action Button ────────────────────────────────────────────────────────────
const ActionButton = ({ id, label, icon, cmd, color, confirm: needsConfirm }) => {
    const isConfirming = () => confirming.value === id;

    const lbl = Label({
        className: "power-btn-label",
        setup: self => {
            self.hook(confirming, () => {
                self.label = isConfirming() ? "Sure?" : label;
            });
        },
    });

    const ico = Icon({
        icon,
        size: 28,
        className: "power-btn-icon",
    });

    const btn = Button({
        className: `power-btn color-${color}`,
        child: Box({
            vertical: true,
            halign: "center",
            valign: "center",
            children: [ico, lbl],
        }),
        onClicked: () => {
            if (needsConfirm && !isConfirming()) {
                // First click: enter confirm state
                confirming.value = id;
                // Auto-cancel after 3s
                setTimeout(() => {
                    if (confirming.value === id) confirming.value = null;
                }, 3000);
                return;
            }
            // Execute
            confirming.value = null;
            App.closeWindow("powermenu");
            setTimeout(() => execAsync(cmd).catch(console.error), 200);
        },
    });

    // Cancel confirm if another button is clicked
    btn.hook(confirming, () => {
        btn.toggleClassName("confirming", isConfirming());
    });

    return btn;
};

// ─── Menu Content ─────────────────────────────────────────────────────────────
const PowerMenuContent = () => Box({
    className: "power-menu",
    vertical:  true,
    halign:    "center",
    valign:    "center",
    children:  [
        Label({ className: "power-menu-title", label: "Power" }),
        Box({
            className: "power-actions",
            children:  ACTIONS.map(ActionButton),
        }),
        Label({ className: "power-menu-hint", label: "Escape to cancel • Click outside to close" }),
    ],
});

// ─── Overlay (click-outside closes) ──────────────────────────────────────────
const Overlay = () => EventBox({
    className: "power-overlay",
    onPrimaryClick: () => {
        confirming.value = null;
        App.closeWindow("powermenu");
    },
    child: PowerMenuContent(),
});

// ─── Window ───────────────────────────────────────────────────────────────────
export default () => Window({
    name:        "powermenu",
    className:   "powermenu-window",
    visible:     false,
    keymode:     "exclusive",
    anchor:      ["top", "bottom", "left", "right"],
    exclusivity: "ignore",
    layer:       "overlay",
    setup: self => {
        // Close on Escape
        self.keybind("Escape", () => {
            confirming.value = null;
            App.closeWindow("powermenu");
        });
        // Reset confirm state on close
        App.connect("window-toggled", (_, name, visible) => {
            if (name === "powermenu" && !visible) {
                confirming.value = null;
            }
        });
    },
    child: Overlay(),
});

// ─── Global toggle ────────────────────────────────────────────────────────────
globalThis.togglePowerMenu = () => App.toggleWindow("powermenu");
