// =============================================================================
// workspace.js — Hyprland Workspace Service
// =============================================================================

import Hyprland from "resource:///com/github/Aylur/ags/service/hyprland.js";

export default Hyprland;

export const getActiveId    = () => Hyprland.active.workspace.id;
export const getWorkspaces  = () => Hyprland.workspaces;
export const isOccupied     = (id) => Hyprland.workspaces.some(w => w.id === id);
export const isActive       = (id) => Hyprland.active.workspace.id === id;

export const goTo           = (id) => Hyprland.sendMessage(`dispatch workspace ${id}`);
export const moveWindowTo   = (id) => Hyprland.sendMessage(`dispatch movetoworkspace ${id}`);
