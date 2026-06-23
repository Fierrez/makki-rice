// =============================================================================
// dock.js — Floating Dock (Phase 3 — Full Implementation)
// =============================================================================
// Features:
//   - Pinned apps + running app detection
//   - macOS magnification on hover (CSS + JS driven)
//   - Active/running indicator dots
//   - Autohide on fullscreen (via globalThis signal)
//   - Separator between pinned and running-only apps
//   - Right-click context menu stub
// =============================================================================

import { Widget, Utils, App } from "resource:///com/github/Aylur/ags/imports.js";
import Hyprland from "resource:///com/github/Aylur/ags/service/hyprland.js";

const { Box, Button, Icon, Window, Revealer, Label, EventBox } = Widget;
const { execAsync } = Utils;

// ─── Pinned App Definitions ───────────────────────────────────────────────────
const PINNED = [
    { id: "firefox",         icon: "firefox",                    cmd: "firefox",             wmClass: "firefox"       },
    { id: "kitty",           icon: "kitty",                      cmd: "kitty",               wmClass: "kitty"         },
    { id: "thunar",          icon: "thunar",                     cmd: "thunar",              wmClass: "thunar"        },
    { id: "code",            icon: "code",                       cmd: "code",                wmClass: "code-url-handler" },
    { id: "discord",         icon: "discord",                    cmd: "discord",             wmClass: "discord"       },
    { id: "spotify",         icon: "spotify",                    cmd: "spotify-launcher",    wmClass: "spotify"       },
    { id: "telegram",        icon: "org.telegram.desktop",       cmd: "telegram-desktop",    wmClass: "TelegramDesktop" },
    { id: "obsidian",        icon: "obsidian",                   cmd: "obsidian",            wmClass: "obsidian"      },
];

// ─── Running App Detection ────────────────────────────────────────────────────
// Returns set of wmClasses currently open in Hyprland
const runningClasses = () => new Set(
    Hyprland.clients.map(c => c.class?.toLowerCase())
);

const pinnedIds = new Set(PINNED.map(p => p.wmClass.toLowerCase()));

// Running apps that are NOT in the pinned list
const runningExtras = () => Hyprland.clients
    .filter(c => !pinnedIds.has(c.class?.toLowerCase()))
    .filter((c, i, arr) => arr.findIndex(x => x.class === c.class) === i) // unique
    .map(c => ({
        id:      c.class,
        icon:    c.class?.toLowerCase() ?? "application-x-executable",
        cmd:     `hyprctl dispatch focuswindow class:${c.class}`,
        wmClass: c.class,
        running: true,
    }));

// ─── Dock Item Component ──────────────────────────────────────────────────────

const DockItem = ({ id, icon, cmd, wmClass, running = false }) => {
    // Neighbour magnification scale — set via CSS variable on the whole dock
    let magnifyTimeout = null;

    const indicator = Box({ className: "dock-indicator", visible: false });
    const iconWidget = Icon({ icon, size: 34, className: "dock-icon" });
    const tooltip    = Label({ className: "dock-tooltip", label: id, visible: false });

    const btn = Button({
        className: `dock-item${running ? " running" : ""}`,
        attribute: { wmClass, id },
        child: Box({
            vertical: true,
            children: [
                Box({ className: "dock-icon-wrap", children: [iconWidget] }),
                indicator,
            ],
        }),
        tooltipText: id,
        onClicked: () => {
            // Focus if running, launch if not
            const classes = runningClasses();
            if (classes.has(wmClass?.toLowerCase())) {
                execAsync(`hyprctl dispatch focuswindow class:${wmClass}`).catch(() => {});
            } else {
                execAsync(cmd).catch(() => {});
            }
        },
    });

    // Update indicator on Hyprland change
    btn.hook(Hyprland, () => {
        const classes = runningClasses();
        const isRunning = classes.has(wmClass?.toLowerCase());
        const isActive  = Hyprland.active.client?.class?.toLowerCase() === wmClass?.toLowerCase();
        indicator.visible = isRunning;
        btn.toggleClassName("active",  isActive);
        btn.toggleClassName("running", isRunning);
    }, "changed");

    // Magnification: set index on hover for CSS neighbour scaling
    btn.connect("enter-notify-event", (self) => {
        self.toggleClassName("hovered", true);
        const parent = self.get_parent();
        if (parent) {
            const items = parent.get_children();
            const idx   = items.indexOf(self);
            items.forEach((item, i) => {
                const dist = Math.abs(i - idx);
                item.toggleClassName("mag-near",   dist === 1);
                item.toggleClassName("mag-far",    dist === 2);
                item.toggleClassName("mag-center",  dist === 0);
            });
        }
    });

    btn.connect("leave-notify-event", (self) => {
        self.toggleClassName("hovered", false);
        const parent = self.get_parent();
        if (parent) {
            parent.get_children().forEach(item => {
                item.toggleClassName("mag-near",   false);
                item.toggleClassName("mag-far",    false);
                item.toggleClassName("mag-center", false);
            });
        }
    });

    return btn;
};

// ─── Separator ────────────────────────────────────────────────────────────────

const DockSeparator = () => Box({ className: "dock-sep" });

// ─── Dock Content (reactive) ──────────────────────────────────────────────────

const DockContent = () => {
    const container = Box({ className: "dock-items", homogeneous: false });

    const rebuild = () => {
        // Pinned items
        const pinned = PINNED.map(DockItem);

        // Running extras (not pinned)
        const extras = runningExtras().map(app => DockItem({ ...app, running: true }));

        container.children = extras.length > 0
            ? [...pinned, DockSeparator(), ...extras]
            : pinned;
    };

    container.hook(Hyprland, rebuild, "changed");
    rebuild();
    return container;
};

// ─── Dock Shell ───────────────────────────────────────────────────────────────

const DockShell = () => Box({
    className: "dock",
    child: DockContent(),
});

// ─── Autohide Revealer ────────────────────────────────────────────────────────

const dockVisible = Variable(true);

// Exposed so event-router can control it
globalThis.dockShow = () => { dockVisible.value = true; };
globalThis.dockHide = () => { dockVisible.value = false; };

const DockWrapper = () => {
    const rev = Revealer({
        transition: "slide_up",
        transitionDuration: 280,
        revealChild: true,
        child: DockShell(),
    });

    rev.hook(dockVisible, () => { rev.revealChild = dockVisible.value; });
    return rev;
};

// ─── Window ───────────────────────────────────────────────────────────────────

export default () => Window({
    name: "dock",
    className: "dock-window",
    anchor: ["bottom"],
    exclusivity: "normal",
    layer: "top",
    margins: [0, 0, 10, 0],
    child: DockWrapper(),
});
