// =============================================================================
// notifications.js — Notification Popups
// =============================================================================

import { Widget, Utils } from "resource:///com/github/Aylur/ags/imports.js";
import Notifications from "resource:///com/github/Aylur/ags/service/notifications.js";

const { Box, Label, Button, Icon, Window, Revealer } = Widget;

const TIMEOUT = 5000; // ms

const NotificationPopup = (notification) => {
    let timeout;

    const dismiss = () => {
        notification.dismiss();
        clearTimeout(timeout);
    };

    const revealer = Revealer({
        transition: "slide_down",
        transitionDuration: 200,
        revealChild: false,
    });

    const item = Box({
        className: `notification ${notification.urgency}`,
        children: [
            Box({
                className: "notification-icon-box",
                children: [
                    notification.appIcon
                        ? Icon({ icon: notification.appIcon, size: 32 })
                        : Icon({ icon: "dialog-information-symbolic", size: 32 }),
                ],
            }),
            Box({
                className: "notification-content",
                vertical: true,
                hexpand: true,
                children: [
                    Label({
                        className: "notification-title",
                        label: notification.summary,
                        xalign: 0,
                        maxWidthChars: 40,
                        truncate: "end",
                    }),
                    ...(notification.body ? [Label({
                        className: "notification-body",
                        label: notification.body,
                        xalign: 0,
                        maxWidthChars: 50,
                        wrap: true,
                    })] : []),
                ],
            }),
            Button({
                className: "notification-close",
                child: Icon({ icon: "window-close-symbolic", size: 16 }),
                onClicked: dismiss,
            }),
        ],
    });

    revealer.child = item;

    // Animate in
    Utils.idle(() => { revealer.revealChild = true; });

    // Auto-dismiss
    timeout = setTimeout(dismiss, TIMEOUT);

    return revealer;
};

export default () => Window({
    name: "notifications",
    className: "notifications-window",
    anchor: ["top", "right"],
    exclusivity: "normal",
    layer: "overlay",
    margins: [48, 12, 0, 0],
    child: Box({
        vertical: true,
        className: "notifications-list",
        setup: self => {
            self.hook(Notifications, (_, id) => {
                const n = Notifications.getNotification(id);
                if (n) self.pack_start(NotificationPopup(n), false, false, 0);
            }, "notified");
        },
    }),
});
