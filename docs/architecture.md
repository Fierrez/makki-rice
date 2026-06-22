# Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────┐
│                    makki-rice                           │
│                                                         │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────┐ │
│  │  Hyprland   │───▶│ Event Router │───▶│    AGS     │ │
│  │ compositor  │    │  (socket2)   │    │  UI engine │ │
│  └─────────────┘    └──────────────┘    └────────────┘ │
│         │                  │                  │         │
│         ▼                  ▼                  ▼         │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────┐ │
│  │   config/   │    │   scripts/   │    │  widgets/  │ │
│  │  (static)   │    │  (behavior)  │    │  (render)  │ │
│  └─────────────┘    └──────────────┘    └────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Layer Breakdown

### 1. Compositor Layer — Hyprland
- Window management, tiling, gaps, borders
- Animation definitions (bezier curves)
- Monitor configuration
- Input handling (keyboard, touchpad, mouse)
- Wayland protocol support

**Config location:** `config/hypr/`

### 2. UI Engine Layer — AGS
- Reactive GTK widget system
- Dynamic Island (expandable status pill)
- Floating app dock
- Notification popups
- JavaScript-driven state management
- SCSS styling system

**Config location:** `ui-engine/ags/`

### 3. Script Layer — Bash
- System event handlers (volume, brightness, battery, network)
- Emits signals to AGS on state change
- Idempotent, composable, testable

**Location:** `scripts/`

### 4. Service Layer — Event Router
- Listens to Hyprland IPC socket (`.socket2.sock`)
- Routes events to appropriate handlers
- Runs as a systemd user service

**Location:** `services/hyprland/event-router.sh`

## Event Flow

```
Hardware Event
     │
     ▼
Hyprland IPC socket2
     │
     ▼
services/hyprland/event-router.sh
     │
     ├─▶ scripts/system/audio.sh (volume change)
     ├─▶ scripts/system/brightness.sh
     ├─▶ ags -r "..." (direct AGS call)
     └─▶ notify-send (notification)
                  │
                  ▼
          AGS Widget Update
                  │
                  ▼
         Animated UI Response
```

## Data Flow

```
System State ──▶ AGS Service ──▶ Widget Hook ──▶ UI Render
    │                │                │
 pamixer         Audio.js         island.js
 brightnessctl   Battery.js       dock.js
 nmcli           Network.js       notifications.js
 hyprctl         Workspace.js
```

## File Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Scripts | kebab-case.sh | `audio.sh`, `link-config.sh` |
| AGS widgets | camelCase.js | `island.js`, `dock.js` |
| SCSS | kebab-case.scss | `main.scss`, `variables.scss` |
| Hyprland conf | kebab-case.conf | `bindings.conf`, `rules.conf` |
| Docs | kebab-case.md | `architecture.md` |

## Scope Rules

- **config/** — Read only at runtime. Static compositor rules.
- **ui-engine/** — Only AGS reads/executes this.
- **scripts/** — Called by keybinds or the event router.
- **services/** — Long-running daemons.
- **assets/** — Referenced by config/scripts, never modified at runtime.
