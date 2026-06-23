// =============================================================================
// widgets/submap.js — Submap Overlay Indicator
// =============================================================================
// Shows a centered HUD when a Hyprland submap is active.
// Displays the submap name and available bindings.
// Disappears automatically when submap exits.
// =============================================================================

import { Widget, Utils } from "resource:///com/github/Aylur/ags/imports.js";
import Hyprland from "resource:///com/github/Aylur/ags/service/hyprland.js";
import { isSubmap } from "../services/bridge.js";

const { Box, Label, Window, Revealer, Icon } = Widget;

// ─── Submap keybinding hints ──────────────────────────────────────────────────
// Extend this map as you add submaps in hyprland.conf
const SUBMAP_HINTS = {
    resize: [
        { key: "H / ←",  action: "Shrink width"   },
        { key: "L / →",  action: "Grow width"      },
        { key: "K / ↑",  action: "Shrink height"   },
        { key: "J / ↓",  action: "Grow height"     },
        { key: "Escape", action: "Exit"             },
    ],
    passthrough: [
        { key: "SUPER + F4", action: "Exit passthrough" },
    ],
};

// ─── Hint row ─────────────────────────────────────────────────────────────────
const HintRow = ({ key, action }) => Box({
    className: "submap-hint-row",
    children: [
        Label({ className: "submap-key",    label: key,    xalign: 0 }),
        Label({ className: "submap-sep",    label: "→"               }),
        Label({ className: "submap-action", label: action, xalign: 0 }),
    ],
});

// ─── Submap content ───────────────────────────────────────────────────────────
const SubmapContent = () => {
    const nameLabel = Label({ className: "submap-name" });
    const hintBox   = Box({ className: "submap-hints", vertical: true });

    const update = () => {
        const name = isSubmap.value;
        nameLabel.label = name ? `${name.toUpperCase()} MODE` : "";

        const hints = SUBMAP_HINTS[name] ?? [];
        hintBox.children = hints.map(HintRow);
    };

    nameLabel.hook(isSubmap, update);
    return Box({
        className: "submap-box",
        vertical: true,
        halign: "center",
        valign: "center",
        children: [
            Box({ className: "submap-icon-row", children: [
                Icon({ icon: "preferences-desktop-keyboard-symbolic", size: 18, className: "submap-icon" }),
                nameLabel,
            ]}),
            hintBox,
            Label({ className: "submap-escape", label: "Press Escape to exit" }),
        ],
    });
};

// ─── Window ───────────────────────────────────────────────────────────────────
export default () => {
    const rev = Revealer({
        transition:     "crossfade",
        transitionDuration: 200,
        revealChild: false,
        child: SubmapContent(),
    });

    rev.hook(isSubmap, () => {
        rev.revealChild = isSubmap.value !== "";
    });

    return Window({
        name:        "submap",
        className:   "submap-window",
        anchor:      ["bottom"],
        exclusivity: "normal",
        layer:       "overlay",
        margins:     [0, 0, 80, 0],
        visible:     true,
        child: rev,
    });
};
