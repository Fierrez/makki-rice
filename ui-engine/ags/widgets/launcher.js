// =============================================================================
// launcher.js — App Launcher Widget
// =============================================================================
// Triggered via keybind. Shows app search with fuzzy matching.
// =============================================================================

import { Widget, Utils, App } from "resource:///com/github/Aylur/ags/imports.js";

const { Box, Entry, Label, Button, Window, Scrollable, Icon } = Widget;
const { execAsync } = Utils;

const MAX_RESULTS = 8;

// Get all desktop apps
const apps = await execAsync("bash -c \"ls /usr/share/applications/*.desktop 2>/dev/null | head -100\"")
    .then(out => out.split("\n").filter(Boolean))
    .catch(() => []);

const LauncherItem = ({ name, exec, icon }) => Button({
    className: "launcher-item",
    child: Box({
        children: [
            Icon({ icon: icon || "application-x-executable", size: 24, className: "launcher-item-icon" }),
            Label({ label: name, className: "launcher-item-label", hexpand: true, xalign: 0 }),
        ],
    }),
    onClicked: () => {
        App.closeWindow("launcher");
        execAsync(exec.replace(/%[uUfF]/, "")).catch(console.error);
    },
});

export default () => {
    const query = Variable("");
    const results = Variable([]);

    const search = (q) => {
        if (!q) { results.value = []; return; }
        const lower = q.toLowerCase();
        results.value = apps
            .filter(name => name.toLowerCase().includes(lower))
            .slice(0, MAX_RESULTS);
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
                            if (results.value[0]) results.value[0].emit("clicked");
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
                                self.children = results.value.map(r => LauncherItem({ name: r, exec: r, icon: "" }));
                            });
                        },
                    }),
                }),
            ],
        }),
    });
};
