import { App } from "astal/gtk3";
import { Variable } from "astal";
import style from "./style.scss";
import Bar from "./widget/Bar";

// ─── Reactive State Variables (Astal style) ──────────────────────────────────
export const islandType = Variable<string>("");
export const dockVisible = Variable<boolean>(true);
export const activeSubmap = Variable<string>("");
export const isScreencasting = Variable<boolean>(false);

App.start({
    css: style,
    instanceName: "makki-shell",
    request(msg, res) {
        try {
            console.log(`[Astal Request] Received command: "${msg}"`);
            
            // 1. Island Expand: globalThis.islandExpand?.('type', duration)
            if (msg.includes("islandExpand")) {
                const match = msg.match(/islandExpand\?\.?\('([^']+)',\s*([0-9]+)\)/);
                if (match) {
                    const type = match[1];
                    const duration = parseInt(match[2]);
                    islandType.set(type);
                    console.log(`[Island] Expanded: ${type} for ${duration}ms`);
                    
                    // Auto-collapse after duration
                    setTimeout(() => {
                        if (islandType.get() === type) {
                            islandType.set("");
                            console.log(`[Island] Auto-collapsed: ${type}`);
                        }
                    }, duration);
                    
                    res(`expanded ${type}`);
                    return;
                }
            }
            
            // 2. Island Collapse: globalThis.islandCollapse?.()
            if (msg.includes("islandCollapse")) {
                islandType.set("");
                console.log(`[Island] Collapsed manually`);
                res("collapsed");
                return;
            }
            
            // 3. Dock Show/Hide: globalThis.dockShow?.() / globalThis.dockHide?.()
            if (msg.includes("dockShow")) {
                dockVisible.set(true);
                console.log(`[Dock] Set visible: true`);
                res("dock shown");
                return;
            }
            if (msg.includes("dockHide")) {
                dockVisible.set(false);
                console.log(`[Dock] Set visible: false`);
                res("dock hidden");
                return;
            }
            
            // 4. Launcher Toggle: globalThis.toggleLauncher?.()
            if (msg.includes("toggleLauncher")) {
                // Toggles launcher window (handled by Astal CLI toggle or internal toggle)
                console.log(`[Launcher] Toggle requested`);
                App.get_window("launcher")?.set_visible(!App.get_window("launcher")?.get_visible());
                res("launcher toggled");
                return;
            }
            
            // 5. Volume/Brightness/Battery change callbacks:
            if (msg.includes("onVolumeChange")) {
                console.log(`[Audio] Volume change detected`);
                islandType.set("volume");
                setTimeout(() => {
                    if (islandType.get() === "volume") islandType.set("");
                }, 3000);
                res("volume updated");
                return;
            }
            if (msg.includes("onBrightnessChange")) {
                console.log(`[Brightness] Brightness change detected`);
                islandType.set("brightness");
                setTimeout(() => {
                    if (islandType.get() === "brightness") islandType.set("");
                }, 3000);
                res("brightness updated");
                return;
            }
            if (msg.includes("onBatteryCritical")) {
                const match = msg.match(/onBatteryCritical\?\.?\(([0-9]+)\)/);
                const pct = match ? parseInt(match[1]) : 10;
                console.log(`[Battery] Critical warning: ${pct}%`);
                islandType.set("battery");
                setTimeout(() => {
                    if (islandType.get() === "battery") islandType.set("");
                }, 6000);
                res("battery alert sent");
                return;
            }
            
            // 6. Event Router: globalThis.routerNotify?.('event', 'data')
            if (msg.includes("routerNotify")) {
                const match = msg.match(/routerNotify\?\.?\('([^']*)',\s*'([^']*)'\)/);
                if (match) {
                    const event = match[1];
                    const data = match[2];
                    console.log(`[Router] Event routed: ${event} → ${data}`);
                    res(`routed ${event}`);
                    return;
                }
            }
            
            // 7. Submap: globalThis.onSubmap?.('resize')
            if (msg.includes("onSubmap")) {
                const match = msg.match(/onSubmap\?\.?\('([^']*)'\)/);
                if (match) {
                    const submap = match[1];
                    activeSubmap.set(submap);
                    console.log(`[Submap] Active submap updated: ${submap}`);
                    res(`submap set to ${submap}`);
                    return;
                }
            }
            
            // 8. Screencast: globalThis.onScreencast?.(true)
            if (msg.includes("onScreencast")) {
                const match = msg.match(/onScreencast\?\.?\((true|false)\)/);
                if (match) {
                    const active = match[1] === "true";
                    isScreencasting.set(active);
                    console.log(`[Screencast] Active state: ${active}`);
                    res(`screencast active set to ${active}`);
                    return;
                }
            }
            
            // 9. CSS Reload: App.resetCss() or App.applyCss(...)
            if (msg.includes("resetCss") || msg.includes("applyCss")) {
                console.log(`[CSS] Reloading styles`);
                // Reapply the loaded compiled css
                App.apply_css(style);
                res("css reloaded");
                return;
            }
            
            res(`Unknown request: ${msg}`);
        } catch (e: any) {
            console.error(`[Astal Request Error] ${e}`);
            res(`error: ${e.message}`);
        }
    },
    main() {
        console.log("[Astal Shell] Starting main interface...");
        // Instantiates the Bar (Dynamic Island) on all active monitors
        App.get_monitors().map(Bar);
    },
});
