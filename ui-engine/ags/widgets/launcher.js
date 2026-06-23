// =============================================================================
// launcher.js — App Launcher Widget
// =============================================================================
// Triggered via keybind. Shows app search with fuzzy matching.
// =============================================================================

import { Widget, Utils, App, Service, Variable } from "resource:///com/github/Aylur/ags/imports.js";

const { Box, Entry, Label, Button, Window, Scrollable, Icon } = Widget;

const MAX_RESULTS = 8;
const applications = await Service.import("applications");

const LauncherItem = (app) => Button({
    className: "launcher-item",
    child: Box({
        children: [
            Icon({ icon: app.icon_name || "application-x-executable", size: 24, className: "launcher-item-icon" }),
            Label({ label: app.name, className: "launcher-item-label", hexpand: true, xalign: 0 }),
        ],
    }),
    onClicked: () => {
        App.closeWindow("launcher");
        app.launch();
    },
});

export default () => {
    const query = Variable("");
    const results = Variable([]);

    const search = (q) => {
        if (!q) { results.value = []; return; }
        results.value = applications.query(q).slice(0, MAX_RESULTS);
    };

    return Window({
        name: "launcher",
        visible: false,
        keymode: "exclusive",
        className: "launcher-window",
        anchor: ["top"],
        margins: [120, 0, 0, 0],
        child: Box({
            className: "launcher",
            vertical: true,
            children: [
                Entry({
                    className: "launcher-entry",
                    placeholderText: "Search apps...",
                    setup: self => {
                        self.hook(query, () => search(query.value));
                        self.connect("changed", (e) => { query.value = e.text; });
                        self.connect("activate", () => {
                            if (results.value[0]) {
                                App.closeWindow("launcher");
                                results.value[0].launch();
                            }
                        });
                    },
                }),
                Scrollable({
                    vscroll: "automatic",
                    hscroll: "never",
                    child: Box({
                        vertical: true,
                        className: "launcher-results",
                        setup: self => {
                            self.hook(results, () => {
                                self.children = results.value.map(app => LauncherItem(app));
                            });
                        },
                    }),
                }),
            ],
        }),
    });
};
