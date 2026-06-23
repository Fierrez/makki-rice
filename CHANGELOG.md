# Changelog

All notable changes to makki-rice are documented here.

---

## [Unreleased]

## [0.6.0] — 2026-06-23

### Phase 6 — Theme System
- `config/themes/catppuccin-frappe.js` — Frappé palette definition
- `config/themes/catppuccin-macchiato.js` — Macchiato palette definition
- `scripts/system/theme-switch.sh` — One-command theme switcher:
  - GTK 3 + GTK 4 settings.ini
  - gsettings (icon, cursor, color-scheme)
  - Default cursor index.theme
  - swww wallpaper transition (grow from center)
  - Hyprland border color via `hyprctl keyword`
  - SCSS rebuild → AGS hot-reload
  - Persists selection to `~/.cache/makki-rice/current-theme`
- `tools/dev/gen-theme-vars.mjs` — Node.js ES module that reads theme JS → generates `variables.scss`
- `tools/dev/build-css.sh` — Updated: calls gen-theme-vars first, added `--watch` mode, `--theme` flag
- `config/kitty/kitty.conf` — Full Kitty terminal config (Mocha palette, JetBrains Mono Nerd Font, tab powerline)
- `Makefile` — Developer task runner (css, watch, theme, health, log, reload, ags-restart)
- `autostart.conf` — Fixed wallpaper path, added startup theme apply, XDG portal ordering
- `bindings.conf` — Added `SUPER+ALT+1-4` theme switching, `SUPER+SHIFT+Q` power menu, `SUPER+SHIFT+R` CSS reload

---

## [0.5.0] — 2026-06-23

### Phase 5 — Bootstrap Hardening
- `bootstrap.sh` — Flags: `--dry-run`, `--skip-packages`, `--skip-link`, `--skip-init`, `--health`
  - /etc/os-release distro detection (Arch/Fedora/Debian/NixOS)
  - Phase runner with per-phase error isolation
  - SCSS compile step on bootstrap
  - Optional post-install health check
- `scripts/bootstrap/packages.sh` — Hardened package installer:
  - Multi-distro: pacman, AUR (yay/paru), dnf, apt
  - Skip-installed check per package
  - Dry-run mode via `DRY_RUN=true`
  - Rollback list to `tools/logs/installed-packages.txt`

---

## [0.4.0] — 2026-06-23

### Phase 4 — Event Routing Engine
- `services/hyprland/event-router.sh` — Full rewrite:
  - **Complete socket2 event map** — all known Hyprland events handled
  - Per-event `rate_limit` function (nanosecond timestamps, configurable cooldown)
  - `dedupe` — skip repeated identical events
  - Dispatch table `case` — maps events to handler functions
  - JSON structured logging with 2 MB rotation
  - Graceful shutdown on `SIGTERM/SIGINT/SIGHUP`
  - AGS bridge wrappers: `ags_island_expand`, `ags_dock_show/hide`, `ags_notify`
- `ui-engine/ags/services/bridge.js` — AGS-side signal bridge:
  - Internal pub/sub event bus (`onBridgeEvent`, `emit`)
  - `globalThis.routerNotify` — generic signal from shell
  - `globalThis.onSubmap` — submap state
  - `globalThis.onScreencast` — screen sharing indicator
  - `globalThis.onBrightnessChange` — reads sysfs then expands island
  - `globalThis.onVolumeChange` — volume island trigger
  - `globalThis.onBatteryCritical` — low battery alert
  - `globalThis.bridgeDebug` — toggle to log all events
- `tools/debug/event-log.sh` — Log viewer: live, filter, last N, stats, clear
- `tools/debug/health-check.sh` — Full system health: deps, symlinks, procs, socket, services

---

## [0.3.0] — 2026-06-23

### Phase 3 — Floating Dock + New Widgets
- `ui-engine/ags/widgets/dock.js` — Full implementation
- `ui-engine/ags/widgets/submap.js` — Submap overlay HUD with keybinding hints
- `ui-engine/ags/widgets/powermenu.js` — Power menu (5 actions, two-click confirm, Escape close)
- `config/swaync/` — Notification center (MPRIS, DND, volume, backlight widgets)
- `config/rofi/` — Fuzzy launcher theme (Catppuccin Mocha)
- `config/wofi/` — App launcher theme
- `config/waybar/` — Stub (AGS is primary)
- `ui-engine/eww/` — EWW fallback bar
- `scripts/ui/` — Bridge scripts (island, dock, launcher, workspace)
- `config/hypr/hypridle.conf` — Idle daemon (dim/lock/display-off/suspend)
- `config/hypr/hyprlock.conf` — Lock screen (blurred screenshot bg, clock, password field)

---

## [0.2.0] — 2026-06-23

### Phase 2 — Dynamic Island
- `ui-engine/ags/widgets/island.js` — 6-mode state machine (idle/volume/brightness/battery/network/media)
- `ui-engine/ags/style/main.scss` — Full stylesheet for all modes
- `scripts/ui/island.sh` — Shell bridge for all island modes

---

## [0.1.0] — 2026-06-22

### Phase 1 — Foundation
- Initial repository scaffold
- Hyprland split configs, bootstrap/install/uninstall scripts
- AGS config skeleton, SCSS design system (Catppuccin Mocha tokens)
- Event router service + systemd unit
- System scripts (audio, brightness, battery, network)
- Documentation (architecture, ui-flow, keybindings, roadmap)
