// =============================================================================
// battery.js — Battery Service
// =============================================================================

import Battery from "resource:///com/github/Aylur/ags/service/battery.js";

export default Battery;

export const getPercent   = () => Battery.percent ?? 100;
export const isCharging   = () => Battery.charging ?? false;
export const isLow        = () => (Battery.percent ?? 100) < 20;
export const isCritical   = () => (Battery.percent ?? 100) < 10;

export const getIcon = () => {
    const pct = getPercent();
    if (isCharging()) return "battery-good-charging-symbolic";
    if (pct > 80) return "battery-full-symbolic";
    if (pct > 50) return "battery-good-symbolic";
    if (pct > 20) return "battery-low-symbolic";
    return "battery-empty-symbolic";
};
