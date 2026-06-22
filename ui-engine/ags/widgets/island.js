// =============================================================================
// island.js — Dynamic Island Widget
// =============================================================================
// A macOS-inspired adaptive status island that expands on system events.
// Collapses to a minimal pill when idle.
// =============================================================================

import { Widget, Utils, Service } from "resource:///com/github/Aylur/ags/imports.js";
import Audio from "../services/audio.js";
import Battery from "../services/battery.js";
import Network from "../services/network.js";
import Workspaces from "../services/workspace.js";

const { Box, Label, Button, Icon, Revealer, EventBox, Window } = Widget;
const { execAsync, interval } = Utils;

// ─── State ───────────────────────────────────────────────────────────────────
let expandTimeout = null;
let isExpanded = false;

const expandState = Variable(false);
const activeContent = Variable("idle"); // "idle" | "volume" | "brightness" | "battery" | "network"

// ─── Expand / Collapse Logic ──────────────────────────────────────────────────
function expand(content = "idle", duration = 3000) {
    if (expandTimeout) clearTimeout(expandTimeout);
    activeContent.value = content;
    expandState.value = true;
    expandTimeout = setTimeout(() => {
        expandState.value = false;
        activeContent.value = "idle";
    }, duration);
}

// ─── Sub-Widgets ──────────────────────────────────────────────────────────────

const Clock = () => Label({
    className: "island-clock",
    setup: self => {
        interval(1000, () => {
            const now = new Date();
            self.label = now.toLocaleTimeString("en-US", {
                hour: "2-digit",
                minute: "2-digit",
                hour12: false,
            });
        });
    },
});

const WorkspaceIndicator = () => Box({
    className: "workspace-pills",
    children: Array.from({ length: 9 }, (_, i) => i + 1).map(n =>
        Widget.Box({
            className: "workspace-pill",
            attribute: { ws: n },
            setup: self => {
                self.hook(Hyprland, () => {
                    const active = Hyprland.active.workspace.id === n;
                    const occupied = Hyprland.workspaces.find(w => w.id === n);
                    self.toggleClassName("active", active);
                    self.toggleClassName("occupied", !!occupied && !active);
                    self.toggleClassName("empty", !occupied);
                });
            },
        })
    ),
});

const VolumeExpanded = () => Box({
    className: "island-expanded volume",
    children: [
        Icon({ icon: "audio-volume-high-symbolic", className: "island-icon" }),
        Widget.Slider({
            className: "island-slider",
            drawValue: false,
            hexpand: true,
            setup: self => {
                self.hook(Audio, () => {
                    self.value = Audio.speaker?.volume ?? 0;
                });
                self.connect("change-value", (_, event) => {
                    Audio.speaker.volume = event.value;
                });
            },
        }),
        Label({
            className: "island-percent",
            setup: self => {
                self.hook(Audio, () => {
                    self.label = `${Math.round((Audio.speaker?.volume ?? 0) * 100)}%`;
                });
            },
        }),
    ],
});

const IdleContent = () => Box({
    className: "island-idle",
    children: [
        WorkspaceIndicator(),
        Clock(),
    ],
});

const ExpandedContent = () => Widget.Stack({
    transition: "slide_left_right",
    transitionDuration: 200,
    children: {
        idle: IdleContent(),
        volume: VolumeExpanded(),
    },
    setup: self => {
        self.hook(activeContent, () => {
            self.shown = activeContent.value;
        });
    },
});

// ─── Island Container ─────────────────────────────────────────────────────────
const IslandContainer = () => Widget.Box({
    name: "island-container",
    className: "island",
    setup: self => {
        self.hook(expandState, () => {
            self.toggleClassName("expanded", expandState.value);
        });
    },
    children: [
        Revealer({
            transition: "slide_right",
            revealChild: true,
            child: ExpandedContent(),
        }),
    ],
});

// ─── Hook audio change → expand island ────────────────────────────────────────
const setupEventHooks = () => {
    Audio.connect("speaker-changed", () => expand("volume", 3000));
};

// ─── Window ───────────────────────────────────────────────────────────────────
export default () => {
    setupEventHooks();

    return Window({
        name: "island",
        className: "island-window",
        anchor: ["top"],
        exclusivity: "exclusive",
        layer: "top",
        margins: [12, 0, 0, 0],
        child: IslandContainer(),
    });
};
