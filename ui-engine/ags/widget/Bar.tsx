import { App, Astal, Gtk, Gdk } from "astal/gtk3";
import { bind, Variable } from "astal";
import Hyprland from "gi://AstalHyprland";
import Tray from "gi://AstalTray";
import { islandType } from "../app";

// ─── Hyprland Workspaces Widget ───────────────────────────────────────────────
function Workspaces() {
    const hypr = Hyprland.get_default();
    
    return (
        <box className="Workspaces" spacing={4}>
            {bind(hypr, "workspaces").as(wss => 
                wss.sort((a, b) => a.id - b.id)
                   .map(ws => (
                        <button
                            className={bind(hypr, "focusedWorkspace").as(fws => 
                                fws && fws.id === ws.id ? "focused active" : ""
                            )}
                            onClicked={() => ws.focus()}>
                            <label label={String(ws.id)} />
                        </button>
                   ))
            )}
        </box>
    );
}

// ─── Clock Widget ────────────────────────────────────────────────────────────
function Clock() {
    const time = Variable("").poll(1000, 'date "+%H:%M"');
    
    return (
        <box className="Clock">
            <label label={time()} />
        </box>
    );
}

// ─── System Tray Widget ──────────────────────────────────────────────────────
function Systray() {
    const tray = Tray.get_default();
    
    return (
        <box className="Systray" spacing={6}>
            {bind(tray, "items").as(items => 
                items.map(item => (
                    <button
                        tooltipMarkup={bind(item, "tooltipMarkup")}
                        onClicked={() => item.activate(0, 0)}
                        className="tray-item">
                        <icon gicon={bind(item, "gicon")} />
                    </button>
                ))
            )}
        </box>
    );
}

// ─── Dynamic Island Component ─────────────────────────────────────────────────
function DynamicIsland() {
    return (
        <box 
            className={bind(islandType).as(type => `IslandPill ${type ? "expanded " + type : "collapsed"}`)} 
            halign="center">
            {bind(islandType).as(type => {
                if (!type) {
                    // Collapsed state: standard status bar elements
                    return (
                        <box className="island-collapsed-content" spacing={16} valign="center">
                            <Workspaces />
                            <Clock />
                            <Systray />
                        </box>
                    );
                }
                
                // Expanded states depending on trigger event type
                if (type === "volume") {
                    return (
                        <box className="island-volume-content" spacing={8} valign="center" halign="center">
                            <label label="󰕾" className="volume-icon" />
                            <label label="Volume Changed" className="volume-label" />
                        </box>
                    );
                }
                if (type === "brightness") {
                    return (
                        <box className="island-brightness-content" spacing={8} valign="center" halign="center">
                            <label label="󰃠" className="brightness-icon" />
                            <label label="Brightness Changed" className="brightness-label" />
                        </box>
                    );
                }
                if (type === "battery") {
                    return (
                        <box className="island-battery-content" spacing={8} valign="center" halign="center">
                            <label label="󰂃" className="battery-icon" />
                            <label label="Battery Critical!" className="battery-label" />
                        </box>
                    );
                }
                
                // Fallback / notification alerts
                return (
                    <box className="island-custom-content" valign="center" halign="center">
                        <label label={`Notification: ${type}`} />
                    </box>
                );
            })}
        </box>
    );
}

// ─── Bar / Window Component ──────────────────────────────────────────────────
export default function Bar(monitor: Gdk.Monitor) {
    return (
        <window
            className="DynamicIslandWindow"
            monitor={monitor}
            exclusivity={Astal.Exclusivity.EXCLUSIVE}
            anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
            application={App}>
            
            <box className="bar-container" halign="center">
                <DynamicIsland />
            </box>
        </window>
    );
}
