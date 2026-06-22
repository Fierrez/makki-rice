// =============================================================================
// clock.js — Clock Widget (standalone)
// =============================================================================

import { Widget, Utils } from "resource:///com/github/Aylur/ags/imports.js";

const { Label, Box } = Widget;
const { interval } = Utils;

export default () => {
    const timeLabel = Label({ className: "clock-time" });
    const dateLabel = Label({ className: "clock-date" });

    const update = () => {
        const now = new Date();
        timeLabel.label = now.toLocaleTimeString("en-US", {
            hour: "2-digit",
            minute: "2-digit",
            second: "2-digit",
            hour12: false,
        });
        dateLabel.label = now.toLocaleDateString("en-US", {
            weekday: "short",
            month: "short",
            day: "numeric",
        });
    };

    update();
    interval(1000, update);

    return Box({
        className: "clock-widget",
        vertical: true,
        halign: "center",
        children: [timeLabel, dateLabel],
    });
};
