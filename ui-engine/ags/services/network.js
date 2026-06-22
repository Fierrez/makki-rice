// =============================================================================
// network.js — Network Service
// =============================================================================

import Network from "resource:///com/github/Aylur/ags/service/network.js";

export default Network;

export const getIcon = () => {
    if (Network.wifi?.enabled) {
        const strength = Network.wifi?.strength ?? 0;
        if (strength > 75) return "network-wireless-signal-excellent-symbolic";
        if (strength > 50) return "network-wireless-signal-good-symbolic";
        if (strength > 25) return "network-wireless-signal-ok-symbolic";
        return "network-wireless-signal-weak-symbolic";
    }
    if (Network.wired?.internet === "connected") return "network-wired-symbolic";
    return "network-offline-symbolic";
};

export const getSsid     = () => Network.wifi?.ssid ?? "Disconnected";
export const isConnected = () => Network.connectivity === "full";
