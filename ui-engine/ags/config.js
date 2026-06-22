// =============================================================================
// config.js — AGS Root Configuration
// =============================================================================
// This is the entry point for the AGS UI engine.
// Import all widgets and services here.
// =============================================================================

import { App } from "resource:///com/github/Aylur/ags/app.js";

// ─── Services ────────────────────────────────────────────────────────────────
import "./services/audio.js";
import "./services/battery.js";
import "./services/network.js";
import "./services/workspace.js";

// ─── Widgets ─────────────────────────────────────────────────────────────────
import Island from "./widgets/island.js";
import Dock from "./widgets/dock.js";
import Notifications from "./widgets/notifications.js";

// ─── App Config ──────────────────────────────────────────────────────────────
App.config({
    style: "./style/main.css",

    windows: [
        // Dynamic Island (top-center status bar)
        Island(),

        // Floating Dock (bottom-center)
        Dock(),

        // Notification popups
        Notifications(),
    ],

    // Quit cleanly on SIGTERM
    closeWindowDelay: {
        "island": 200,
        "dock": 150,
    },
});

export {};
