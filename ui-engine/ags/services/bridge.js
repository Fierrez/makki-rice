// =============================================================================
// services/bridge.js — Shell ↔ AGS Signal Bridge
// =============================================================================
// Exposes globalThis functions that bash scripts call via `ags -r "..."`.
// Centralizes all inbound signal handling in one place.
//
// Usage from shell:
//   ags -r "globalThis.routerSignal('volume', {})"
//   ags -r "globalThis.islandExpand('brightness', 3000)"
// =============================================================================

import { Utils, Variable } from "resource:///com/github/Aylur/ags/imports.js";
import Notifications from "resource:///com/github/Aylur/ags/service/notifications.js";

const { execAsync } = Utils;

// ─── Internal event bus ───────────────────────────────────────────────────────
// Other modules can subscribe to bridge events.
const listeners = new Map();

export function onBridgeEvent(event, callback) {
    if (!listeners.has(event)) listeners.set(event, []);
    listeners.get(event).push(callback);
}

function emit(event, payload = {}) {
    (listeners.get(event) ?? []).forEach(cb => {
        try { cb(payload); } catch (e) {
            console.error(`[bridge] Listener error on "${event}":`, e);
        }
    });
    (listeners.get("*") ?? []).forEach(cb => {
        try { cb({ event, ...payload }); } catch (e) {}
    });
}

// ─── Screen state ─────────────────────────────────────────────────────────────
export const isScreencasting = Variable(false);
export const isSubmap        = Variable("");

// ─── Public API — called by event-router.sh via ags -r ───────────────────────

/**
 * Generic router signal dispatcher.
 * Bash calls: ags -r "globalThis.routerNotify('monitoradded', 'DP-2')"
 */
globalThis.routerNotify = (event, data = "") => {
    console.log(`[bridge] routerNotify: ${event} → ${data}`);
    emit(event, { data });
};

/**
 * Submap activation.
 * Bash calls: ags -r "globalThis.onSubmap('resize')"
 */
globalThis.onSubmap = (name) => {
    isSubmap.value = name ?? "";
    emit("submap", { name });
    console.log(`[bridge] submap → "${name}"`);
};

/**
 * Screencast state.
 * Bash calls: ags -r "globalThis.onScreencast(true)"
 */
globalThis.onScreencast = (active) => {
    isScreencasting.value = !!active;
    emit("screencast", { active });
};

/**
 * Brightness change signal (from brightness.sh).
 * Reads current brightness from sysfs then triggers island.
 */
globalThis.onBrightnessChange = async () => {
    try {
        const rawStr = await execAsync("bash -c \"cat /sys/class/backlight/*/brightness 2>/dev/null | head -1\"");
        const maxStr = await execAsync("bash -c \"cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -1\"");
        const raw = parseInt(rawStr.trim());
        const max = parseInt(maxStr.trim());
        if (!isNaN(raw) && !isNaN(max) && max > 0) {
            const pct = Math.round((raw / max) * 100);
            emit("brightness", { percent: pct });
            globalThis.islandExpand?.("brightness", 3000);
        }
    } catch (e) {
        console.warn("[bridge] brightness read failed:", e.message);
    }
};

/**
 * Volume change signal (from audio.sh).
 */
globalThis.onVolumeChange = () => {
    emit("volume", {});
    globalThis.islandExpand?.("volume", 3000);
};

/**
 * Battery critical/low signal (from battery.sh watch mode).
 */
globalThis.onBatteryCritical = (pct) => {
    emit("battery-critical", { percent: pct });
    globalThis.islandExpand?.("battery", pct <= 10 ? 10000 : 6000);
};

/**
 * Debug helper: log all events to console.
 * Activate via: ags -r "globalThis.bridgeDebug = true"
 */
globalThis.bridgeDebug = false;

onBridgeEvent("*", (payload) => {
    if (globalThis.bridgeDebug) {
        console.log("[bridge:debug]", JSON.stringify(payload));
    }
});

export default { onBridgeEvent, emit, isScreencasting, isSubmap };
