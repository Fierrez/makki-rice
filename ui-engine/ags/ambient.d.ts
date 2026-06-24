// Ambient module declarations for GObject Introspection and Astal typelibs
declare module "astal/gtk3" {
    export const App: any;
    export const Astal: any;
    export const Gtk: any;
    export const Gdk: any;
}
declare module "astal" {
    export const bind: any;
    export const Variable: any;
}
declare module "gi://AstalHyprland" {
    const Hyprland: any;
    export default Hyprland;
}
declare module "gi://AstalTray" {
    const Tray: any;
    export default Tray;
}
