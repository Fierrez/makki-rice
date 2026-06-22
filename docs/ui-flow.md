# UI Flow — Event → Animation Pipeline

## Concept

Every visible UI change is triggered by a system event.
There are no polling loops in the UI layer — everything is reactive.

## Event Sources

| Source | Mechanism | Example |
|--------|----------|---------|
| Keybind | Hyprland `bind` | `SUPER+Q` → kill window |
| Hardware key | `bindel` / `bindl` | Volume key → audio.sh |
| Hyprland IPC | socket2 stream | workspace change → island update |
| System daemon | Polling script | battery watch → notification |
| AGS service | GObject signal | Audio service → widget hook |

## Flow 1: Volume Change

```
User presses Volume Up key
        │
        ▼
Hyprland dispatches: exec audio.sh up
        │
        ▼
audio.sh:
  - pamixer --set-volume N
  - ags -r "onVolumeChange()"
        │
        ▼
AGS Audio service: speaker-changed signal
        │
        ▼
island.js: hook fires
  - expand("volume", 3000)
  - expandState = true
  - shows VolumeExpanded widget
        │
        ▼
Island animates: pill expands → shows slider + percentage
        │
    (3 seconds)
        ▼
Auto-collapse: expandState = false → island shrinks
```

## Flow 2: Workspace Switch

```
User presses SUPER+2
        │
        ▼
Hyprland switches workspace
        │
        ▼
socket2 emits: workspace>>2
        │
        ▼
event-router.sh: on_workspace_change "2"
        │
        ▼
AGS Hyprland service: active.workspace updates
        │
        ▼
WorkspaceIndicator hook fires:
  - pill #2 → .active class (expands to 20px, gradient fill)
  - pill #1 → .occupied class (gray)
        │
        ▼
Smooth CSS transition animation
```

## Flow 3: Fullscreen Toggle

```
User presses SUPER+F
        │
        ▼
Hyprland: window goes fullscreen
        │
        ▼
socket2 emits: fullscreen>>1
        │
        ▼
event-router.sh: on_fullscreen "1"
  - ags -r "App.getWindow('dock')?.hide()"
        │
        ▼
Dock window hides (slide_down transition)
        │
    (user exits fullscreen)
        ▼
socket2 emits: fullscreen>>0
        │
        ▼
event-router.sh: on_fullscreen "0"
  - ags -r "App.getWindow('dock')?.show()"
        │
        ▼
Dock slides back up
```

## AGS Widget Lifecycle

```
App.config() called
      │
      ▼
Window created → layer shell positioned
      │
      ▼
Widget tree constructed
      │
      ▼
Service hooks registered (Audio, Battery, Network, Hyprland)
      │
      ▼
Event loop runs (GLib main loop)
      │
      ▼
On signal → hook fires → widget re-renders
```

## Animation Timing

| Widget | Expand | Collapse | Curve |
|--------|--------|----------|-------|
| Island | 250ms | 300ms | spring |
| Dock | 200ms | 150ms | slide_up |
| Notifications | 200ms | 150ms | slide_down |
| Launcher | 180ms | 150ms | fade |
| Workspace pill | 200ms | 200ms | ease |
