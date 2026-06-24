# Changelog

All notable changes to makki-rice are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Dynamic hardware and VM environment boot override script (`scripts/system/detect-hw.sh`) that dynamically configures Hyprland.
- Interactive verification prompt and selection menu fallback inside `detect-hw.sh` during auto-detection mode.
- Override parameters (`--nvidia`, `--vm`, `--intel-amd`, `--auto`) in `bootstrap.sh` and `install.sh` to allow forcing specific hardware/rendering profiles during installation.
- Dynamic environment loading support in `config/hypr/env.conf`.

### Fixed
- Renamed all occurrences of the deprecated `swww` command/package and `swww-daemon` to `awww` and `awww-daemon` respectively across all scripts, configurations, and documentation.

---

## [0.6.0] — 2026-06-23

### Added
- Catppuccin themes: Frappé (`config/themes/catppuccin-frappe.js`) and Macchiato (`config/themes/catppuccin-macchiato.js`).
- One-command theme switcher script (`scripts/system/theme-switch.sh`) supporting GTK 3/4 settings, gsettings, default cursor themes, awww wallpaper transitions, Hyprland border color, SCSS rebuilding, and AGS hot-reload.
- Node.js generator script (`tools/dev/gen-theme-vars.mjs`) to convert JavaScript themes into Sass variables (`variables.scss`).
- Developer task runner (`Makefile`) supporting `css`, `watch`, `theme`, `health`, `log`, `reload`, and `ags-restart`.
- Custom Kitty terminal configuration (`config/kitty/kitty.conf`) with Catppuccin Mocha theme, JetBrains Mono font, and powerline style tabs.

### Changed
- Refactored `autostart.conf` to fix the wallpaper path, add startup theme application, and refine XDG portal launch ordering.
- Updated `bindings.conf` to add theme switching shortcuts (`SUPER+ALT+1-4`), power menu (`SUPER+SHIFT+Q`), and CSS reload (`SUPER+SHIFT+R`).
- Updated Sass compilation script `tools/dev/build-css.sh` with `--watch` mode, `--theme` support, and theme variable generation.

---

## [0.5.0] — 2026-06-23

### Added
- Distro detection for Arch, Fedora, Debian, and NixOS inside `bootstrap.sh`.
- Rollback list generation during package installs to `tools/logs/installed-packages.txt`.
- Dry-run mode (`DRY_RUN=true`) and skip options (`--skip-packages`, `--skip-link`, `--skip-init`) for bootstrap phase isolation.

### Changed
- Hardened package installer (`scripts/bootstrap/packages.sh`) to support multiple package managers (pacman, AUR helper, dnf, apt) with skip-installed checks.
- Refactored `bootstrap.sh` to compile SCSS assets on setup and run optional post-install health checks.

---

## [0.4.0] — 2026-06-23

### Added
- Complete Hyprland event routing engine (`services/hyprland/event-router.sh`) with rate limiting, de-duplication, JSON logging, and graceful signals.
- AGS-side signal bridge (`ui-engine/ags/services/bridge.js`) facilitating dynamic island expansion, notification events, screencasting, and audio/brightness indicators.
- Live log viewer script (`tools/debug/event-log.sh`).
- Health checking script (`tools/debug/health-check.sh`) checking dependencies, symlinks, running processes, sockets, and user services.

---

## [0.3.0] — 2026-06-23

### Added
- Floating app dock (`ui-engine/ags/widgets/dock.js`) featuring autohide.
- Submap overlay HUD (`ui-engine/ags/widgets/submap.js`) showing active keybinding hints.
- Power menu widget (`ui-engine/ags/widgets/powermenu.js`) with confirmation steps and escaping.
- SwayNC configuration (`config/swaync/`) for notifications, DND, and widgets.
- Rofi launcher theme (`config/rofi/`) using Catppuccin Mocha.
- App launcher config for Wofi (`config/wofi/`).
- Idle configurations (`config/hypr/hypridle.conf`) and lockscreen designs (`config/hypr/hyprlock.conf`).
- Failback EWW bar configuration (`ui-engine/eww/`).
- UI helper scripts (`scripts/ui/`) for workspace and widget routing.

---

## [0.2.0] — 2026-06-23

### Added
- Dynamic Island status bar widget (`ui-engine/ags/widgets/island.js`) supporting multiple interactive modes.
- Complete SCSS stylesheet (`ui-engine/ags/style/main.scss`) for island styling.
- Shell bridging script (`scripts/ui/island.sh`) for active island updates.

---

## [0.1.0] — 2026-06-22

### Added
- Repository structure and foundation.
- Split Hyprland configuration files.
- Foundation script system for audio, brightness, battery, and network routing.
- Bootstrap and installation scripts (`bootstrap.sh`, `install.sh`, `uninstall.sh`).
- Initial AGS configuration skeleton with design system SCSS variables.
- Systemd user service for running the event router.
- Documentation for project architecture, roadmaps, keybindings, and flow.
