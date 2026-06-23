// =============================================================================
// config.js — AGS Root Configuration (Final)
// =============================================================================

import { App } from "resource:///com/github/Aylur/ags/app.js";

// ─── Bridge (must be first) ───────────────────────────────────────────────────
import "./services/bridge.js";

// ─── Widgets ─────────────────────────────────────────────────────────────────
import Island    from "./widgets/island.js";
import Dock      from "./widgets/dock.js";
import NotifPop  from "./widgets/notifications.js";
import Launcher  from "./widgets/launcher.js";
import Submap    from "./widgets/submap.js";
import PowerMenu from "./widgets/powermenu.js";

// ─── App Config ──────────────────────────────────────────────────────────────
App.config({
    style: App.configDir + "/style/main.css",

    windows: [
        Island(),     // Dynamic Island  — top center
        Dock(),       // Floating Dock   — bottom center
        NotifPop(),   // Notifications   — top right
        Launcher(),   // App launcher    — hidden by default
        Submap(),     // Submap HUD      — bottom center
        PowerMenu(),  // Power menu      — fullscreen overlay, hidden
    ],

    closeWindowDelay: {
        "island":    250,
        "dock":      200,
        "launcher":  180,
        "powermenu": 150,
    },

    onWindowToggled: (name, visible) => {
        console.log(`[AGS] "${name}" → ${visible ? "visible" : "hidden"}`);
    },
});

export {};
