// =============================================================================
// audio.js — Audio Service
// =============================================================================
// Wraps the AGS built-in Audio service with custom signal helpers.
// =============================================================================

import Audio from "resource:///com/github/Aylur/ags/service/audio.js";

// Re-export the built-in service with added helpers
export default Audio;

// Convenience getters
export const getVolume = () => Math.round((Audio.speaker?.volume ?? 0) * 100);
export const getMuted  = () => Audio.speaker?.muted ?? false;

export const setVolume = (v) => {
    if (Audio.speaker) Audio.speaker.volume = Math.max(0, Math.min(1, v));
};

export const toggleMute = () => {
    if (Audio.speaker) Audio.speaker.muted = !Audio.speaker.muted;
};
