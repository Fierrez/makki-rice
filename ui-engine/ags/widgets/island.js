// =============================================================================
// island.js — Dynamic Island Widget (Phase 2 — Full Implementation)
// =============================================================================
// Reactive pill that expands for: volume, brightness, battery, network, media
// Auto-collapses after timeout. State-machine driven.
// =============================================================================

import { Widget, Utils, Variable } from "resource:///com/github/Aylur/ags/imports.js";
import Audio   from "resource:///com/github/Aylur/ags/service/audio.js";
import Battery from "resource:///com/github/Aylur/ags/service/battery.js";
import Network from "resource:///com/github/Aylur/ags/service/network.js";
import Hyprland from "resource:///com/github/Aylur/ags/service/hyprland.js";
import Mpris   from "resource:///com/github/Aylur/ags/service/mpris.js";

const { Box, Label, Icon, Slider, Stack, Revealer, EventBox, Window, Button } = Widget;
const { execAsync, interval, timeout } = Utils;

// ─── State Machine ───────────────────────────────────────────────────────────
// "idle" | "volume" | "brightness" | "battery" | "network" | "media"
const mode      = Variable("idle");
const expanded  = Variable(false);

let collapseTimer = null;

/**
 * Trigger an expansion with a given mode and auto-collapse after `ms`.
 * Calling again while open resets the timer and optionally switches mode.
 */
function triggerExpand(newMode, ms = 3000) {
    if (collapseTimer) {
        collapseTimer.cancel?.();
        clearTimeout(collapseTimer);
    }
    mode.value     = newMode;
    expanded.value = true;
    collapseTimer  = timeout(ms, () => {
        expanded.value = false;
        // Delay mode reset so the collapse animation completes
        timeout(350, () => { mode.value = "idle"; });
    });
}

function forceCollapse() {
    if (collapseTimer) clearTimeout(collapseTimer);
    expanded.value = false;
    timeout(350, () => { mode.value = "idle"; });
}

// ─── Idle Content: workspace pills + clock ────────────────────────────────────

const WorkspacePill = (n) => Box({
    className: "ws-pill",
    setup: self => {
        const update = () => {
            const activeId  = Hyprland.active.workspace.id;
            const occupied  = Hyprland.workspaces.some(w => w.id === n);
            self.toggleClassName("ws-active",   activeId === n);
            self.toggleClassName("ws-occupied", occupied && activeId !== n);
            self.toggleClassName("ws-empty",    !occupied);
        };
        self.hook(Hyprland, update, "changed");
        update();
    },
});

const WorkspaceBar = () => Box({
    className: "ws-bar",
    children: Array.from({ length: 9 }, (_, i) => WorkspacePill(i + 1)),
});

const IslandClock = () => {
    const lbl = Label({ className: "island-clock-label" });
    const update = () => {
        const d = new Date();
        lbl.label = d.toLocaleTimeString("en-US", {
            hour: "2-digit", minute: "2-digit", hour12: false,
        });
    };
    update();
    interval(1000, update);
    return lbl;
};

const IdleView = () => Box({
    className: "island-idle-view",
    children: [WorkspaceBar(), IslandClock()],
});

// ─── Volume View ──────────────────────────────────────────────────────────────

const volumeIcon = () => {
    const v = Audio.speaker?.volume ?? 0;
    const m = Audio.speaker?.muted  ?? false;
    if (m || v === 0) return "audio-volume-muted-symbolic";
    if (v < 0.33)    return "audio-volume-low-symbolic";
    if (v < 0.66)    return "audio-volume-medium-symbolic";
    return "audio-volume-high-symbolic";
};

const VolumeView = () => Box({
    className: "island-expanded-view volume-view",
    children: [
        Icon({ className: "island-exp-icon", setup: self => {
            self.hook(Audio, () => { self.icon = volumeIcon(); }, "speaker-changed");
        }}),
        Slider({
            className: "island-slider",
            drawValue: false,
            hexpand: true,
            min: 0, max: 1,
            setup: self => {
                self.hook(Audio, () => { self.value = Audio.speaker?.volume ?? 0; }, "speaker-changed");
                self.connect("change-value", (s) => {
                    if (Audio.speaker) Audio.speaker.volume = s.value;
                });
            },
        }),
        Label({ className: "island-exp-pct", setup: self => {
            self.hook(Audio, () => {
                const v = Audio.speaker?.muted
                    ? "muted"
                    : `${Math.round((Audio.speaker?.volume ?? 0) * 100)}%`;
                self.label = v;
            }, "speaker-changed");
        }}),
    ],
});

// ─── Brightness View ──────────────────────────────────────────────────────────

const brightnessVal = Variable(100);

// Read brightness from sysfs periodically
const updateBrightness = async () => {
    try {
        const raw = await execAsync("bash -c \"cat /sys/class/backlight/*/brightness 2>/dev/null | head -1\"");
        const max = await execAsync("bash -c \"cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -1\"");
        if (raw && max) brightnessVal.value = Math.round((parseInt(raw) / parseInt(max)) * 100);
    } catch { /* no backlight */ }
};
updateBrightness();

const BrightnessView = () => Box({
    className: "island-expanded-view brightness-view",
    children: [
        Icon({ icon: "display-brightness-symbolic", className: "island-exp-icon" }),
        Slider({
            className: "island-slider",
            drawValue: false,
            hexpand: true,
            min: 5, max: 100,
            setup: self => {
                self.hook(brightnessVal, () => { self.value = brightnessVal.value; });
                self.connect("change-value", (s) => {
                    execAsync(`brightnessctl set ${Math.round(s.value)}%`).catch(() => {});
                    brightnessVal.value = Math.round(s.value);
                });
            },
        }),
        Label({ className: "island-exp-pct", setup: self => {
            self.hook(brightnessVal, () => { self.label = `${brightnessVal.value}%`; });
        }}),
    ],
});

// ─── Battery View ─────────────────────────────────────────────────────────────

const batteryIcon = (pct, charging) => {
    if (charging) return "battery-good-charging-symbolic";
    if (pct > 80) return "battery-full-symbolic";
    if (pct > 50) return "battery-good-symbolic";
    if (pct > 20) return "battery-low-symbolic";
    return "battery-caution-symbolic";
};

const BatteryView = () => Box({
    className: "island-expanded-view battery-view",
    children: [
        Icon({ className: "island-exp-icon", setup: self => {
            self.hook(Battery, () => {
                self.icon = batteryIcon(Battery.percent, Battery.charging);
            });
        }}),
        Box({ className: "battery-detail", vertical: true, vpack: "center", children: [
            Label({ className: "battery-pct", xalign: 0, setup: self => {
                self.hook(Battery, () => { self.label = `${Battery.percent}%`; });
            }}),
            Label({ className: "battery-status", xalign: 0, setup: self => {
                self.hook(Battery, () => {
                    self.label = Battery.charging ? "Charging" : Battery.timeRemaining
                        ? `${Math.floor(Battery.timeRemaining / 3600)}h ${Math.floor((Battery.timeRemaining % 3600) / 60)}m`
                        : "Discharging";
                });
            }}),
        ]}),
    ],
});

// ─── Network View ─────────────────────────────────────────────────────────────

const NetworkView = () => Box({
    className: "island-expanded-view network-view",
    children: [
        Icon({ className: "island-exp-icon", setup: self => {
            self.hook(Network, () => {
                const wifi = Network.wifi;
                if (!wifi?.enabled) { self.icon = "network-offline-symbolic"; return; }
                const s = wifi.strength ?? 0;
                if (s > 75) self.icon = "network-wireless-signal-excellent-symbolic";
                else if (s > 50) self.icon = "network-wireless-signal-good-symbolic";
                else if (s > 25) self.icon = "network-wireless-signal-ok-symbolic";
                else self.icon = "network-wireless-signal-weak-symbolic";
            });
        }}),
        Box({ vertical: true, vpack: "center", children: [
            Label({ className: "network-ssid", xalign: 0, setup: self => {
                self.hook(Network, () => { self.label = Network.wifi?.ssid ?? "Disconnected"; });
            }}),
            Label({ className: "network-detail", xalign: 0, setup: self => {
                self.hook(Network, () => {
                    const s = Network.wifi?.strength ?? 0;
                    self.label = Network.wifi?.enabled ? `Signal: ${s}%` : "Wi-Fi off";
                });
            }}),
        ]}),
    ],
});

// ─── Media View (MPRIS) ───────────────────────────────────────────────────────

const MediaView = () => Box({
    className: "island-expanded-view media-view",
    children: [
        // Album art / app icon
        Box({ className: "media-art-box", setup: self => {
            self.hook(Mpris, () => {
                const player = Mpris.players[0];
                // Try cover art, fallback to app icon
                const art = player?.coverPath;
                self.toggleClassName("has-art", !!art);
                if (art) {
                    self.css = `background-image: url('${art}');`;
                }
            });
        }}),
        // Track info
        Box({ vertical: true, vpack: "center", hexpand: true, className: "media-info", children: [
            Label({ className: "media-title", xalign: 0, truncate: "end", maxWidthChars: 28,
                setup: self => {
                    self.hook(Mpris, () => { self.label = Mpris.players[0]?.trackTitle ?? "Nothing playing"; });
                },
            }),
            Label({ className: "media-artist", xalign: 0, truncate: "end", maxWidthChars: 24,
                setup: self => {
                    self.hook(Mpris, () => { self.label = Mpris.players[0]?.trackArtists?.join(", ") ?? ""; });
                },
            }),
        ]}),
        // Controls
        Box({ className: "media-controls", children: [
            Button({ className: "media-btn", child: Icon({ icon: "media-skip-backward-symbolic", size: 14 }),
                onClicked: () => Mpris.players[0]?.previous(),
            }),
            Button({ className: "media-btn play", setup: self => {
                self.hook(Mpris, () => {
                    const playing = Mpris.players[0]?.playBackStatus === "Playing";
                    self.child.icon = playing ? "media-playback-pause-symbolic" : "media-playback-start-symbolic";
                });
                self.connect("clicked", () => Mpris.players[0]?.playPause());
            }, child: Icon({ size: 16 }) }),
            Button({ className: "media-btn", child: Icon({ icon: "media-skip-forward-symbolic", size: 14 }),
                onClicked: () => Mpris.players[0]?.next(),
            }),
        ]}),
    ],
});

// ─── Stack — all views ────────────────────────────────────────────────────────

const ContentStack = () => Stack({
    transition: "crossfade",
    transitionDuration: 180,
    children: {
        idle:       IdleView(),
        volume:     VolumeView(),
        brightness: BrightnessView(),
        battery:    BatteryView(),
        network:    NetworkView(),
        media:      MediaView(),
    },
    setup: self => {
        self.hook(mode, () => { self.shown = mode.value; });
    },
});

// ─── Island Container ─────────────────────────────────────────────────────────

const IslandContainer = () => Box({
    className: "island",
    setup: self => {
        self.hook(expanded, () => self.toggleClassName("island-expanded", expanded.value));
        self.hook(mode,     () => self.toggleClassName(`mode-${mode.value}`, true));
    },
    children: [ContentStack()],
});

// ─── Event Hooks — wire system signals to island expansions ───────────────────

function setupHooks() {
    // Volume
    Audio.connect("speaker-changed", () => triggerExpand("volume", 3000));

    // Battery — only show on critical/low
    Battery.connect("changed", () => {
        const pct = Battery.percent;
        if (!Battery.charging && (pct <= 20)) {
            triggerExpand("battery", pct <= 10 ? 8000 : 4000);
        }
    });

    // Network — show on connect/disconnect
    Network.connect("changed", () => triggerExpand("network", 3500));

    // Media — show when a new track starts
    Mpris.connect("changed", () => {
        if (Mpris.players[0]?.playBackStatus === "Playing") {
            triggerExpand("media", 4000);
        }
    });
}

// External API: allow scripts to trigger from outside
globalThis.islandExpand    = triggerExpand;
globalThis.islandCollapse  = forceCollapse;
globalThis.onVolumeChange  = () => triggerExpand("volume", 3000);
globalThis.onBrightnessChange = () => {
    updateBrightness().then(() => triggerExpand("brightness", 3000));
};

// ─── Window ───────────────────────────────────────────────────────────────────

export default () => {
    setupHooks();

    return Window({
        name: "island",
        className: "island-window",
        anchor: ["top"],
        exclusivity: "exclusive",
        layer: "top",
        margins: [10, 0, 0, 0],
        child: EventBox({
            onPrimaryClick: forceCollapse,
            child: IslandContainer(),
        }),
    });
};
