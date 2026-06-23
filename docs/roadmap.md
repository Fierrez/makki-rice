# Roadmap

## Phase 1 — Foundation ✅
- [x] Repository scaffolding
- [x] Hyprland base config (split into sub-files)
- [x] Bootstrap installer
- [x] Uninstall script
- [x] AGS config skeleton
- [x] Design token system (SCSS variables)
- [x] Event router service

## Phase 2 — Dynamic Island ✅
- [x] Idle state with workspace pills + clock
- [x] Volume expansion on keypress (with slider)
- [x] Brightness expansion (sysfs + brightnessctl)
- [x] Battery low/critical warning with time remaining
- [x] Network status indicator (WiFi SSID + signal)
- [x] Media player info via MPRIS (title, artist, controls)
- [x] 6-mode state machine with auto-collapse
- [x] Click-to-collapse interaction

## Phase 3 — Floating Dock ✅
- [x] Pinned apps grid
- [x] macOS-style hover magnification (cascade: center/near/far)
- [x] Active app indicator dot
- [x] Autohide on fullscreen (via globalThis signal)
- [x] Running app detection (via Hyprland clients)
- [x] App group separators (pinned vs extras)
- [x] Focus-or-launch behavior

## Phase 4 — Event Routing Engine ✅
- [x] Full socket2 event map (all known Hyprland events)
- [x] Per-event action dispatch table
- [x] AGS signal bridge (bash ↔ JS) — `services/bridge.js`
- [x] Rate-limited event deduplication
- [x] JSON structured logging with 2 MB rotation

## Phase 5 — Full Bootstrap System ✅
- [x] AUR helper auto-detection (yay/paru)
- [x] Non-Arch distro support (Fedora/Debian)
- [x] `--dry-run`, `--skip-*` flags
- [x] Rollback list generation (`tools/logs/installed-packages.txt`)
- [x] Post-install health check integration

## Phase 6 — Theme System ✅
- [x] All 4 Catppuccin flavors (Mocha/Latte/Frappé/Macchiato)
- [x] One-command switcher: GTK3/4 + gsettings + cursor + wallpaper + AGS
- [x] SCSS variable generator from JS theme files
- [x] Keybinds `SUPER+ALT+1-4` for instant switching
- [x] Startup theme restore from cache
- [x] `tools/dev/build-css.sh --watch` mode

## Phase 7 — Power & Performance ✅
- [x] Idle config (hypridle) — dim/lock/display-off/suspend tiers
- [x] Lock screen (hyprlock) — blurred bg, clock, styled password field
- [x] Power menu widget — 5 actions, two-click confirmation, Escape dismiss
- [x] Hyprland keybind: `SUPER+SHIFT+Q` → power menu

## Stretch Goals
- [ ] NixOS / Home Manager module
- [ ] Interactive setup wizard (TUI)
- [ ] AGS widget marketplace
- [ ] Dynamic accent color from wallpaper (matugen)
- [ ] Touchscreen gesture support
- [ ] Per-app GPU assignment (discrete/integrated)
- [ ] VRR / tearing mode per-game toggle
