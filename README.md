<div align="center">

# 🌿 makki-rice

**A Hyprland-based Desktop UX Framework**  
*Event-driven • Modular • Animated • Reactive*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Arch Linux](https://img.shields.io/badge/Platform-Arch%20Linux-1793D1?logo=arch-linux)](https://archlinux.org)
[![Compositor: Hyprland](https://img.shields.io/badge/Compositor-Hyprland-58E1FF)](https://hyprland.org)
[![UI Engine: AGS](https://img.shields.io/badge/UI%20Engine-AGS-a6e3a1)](https://github.com/Aylur/ags)

</div>

---

## ✨ Philosophy

This is not a "rice". It's an **operating layer** built on top of Hyprland.

> Hyprland handles rendering. AGS handles intelligence. Scripts handle behavior.

The system is designed around a single principle:
**Every system event should trigger a visible, animated, purposeful response.**

```
Volume change  →  audio.sh  →  AGS Island expands  →  auto-collapses
Battery low    →  battery.sh →  AGS notification   →  persistent indicator
Network change →  network.sh →  island flashes      →  status updates
```

---

## 🏗️ Architecture

```
makki-rice/
├── config/          # Static compositor & app rules
├── ui-engine/       # AGS reactive UI system (primary)
│   └── ags/         # Widgets, services, styles
├── scripts/         # System automation layer
├── services/        # Hyprland event routing
├── assets/          # Wallpapers, icons, fonts
└── docs/            # Architecture & roadmap
```

### Layer Responsibilities

| Layer | Tool | Role |
|---|---|---|
| Compositor | Hyprland | Window management, rendering |
| UI Brain | AGS | Widgets, animations, reactivity |
| Automation | Bash scripts | System events → UI signals |
| Notifications | swaync | Notification center |
| Launcher | wofi / rofi | App & command launcher |

---

## 🚀 Quick Start

```bash
# Clone the repo
git clone https://github.com/Fierrez/makki-rice ~/.config/makki-rice

# Run the bootstrap installer
cd ~/.config/makki-rice
bash bootstrap.sh
```

> ⚠️ **Arch Linux first.** Other distros may require manual dependency resolution.

---

## 📦 Features

- **Dynamic Island** — macOS-inspired expandable status island
- **Floating Dock** — Intelligent app dock with autohide
- **Event Router** — Hyprland socket → script → UI pipeline
- **Modular Config** — No monolithic files, everything split by concern
- **One-command Install** — Full system bootstrap with `bash bootstrap.sh`
- **AGS-powered UI** — Reactive, GPU-accelerated GTK widgets

---

## 🧩 UI Engine: AGS (Primary)

AGS (Aylur's GTK Shell) is the core UI engine. It provides:
- Real-time reactive widgets
- JavaScript-driven animations
- SCSS styling system
- System service integration (audio, network, battery, workspaces)

**EWW** is available as a minimal fallback in `ui-engine/eww/`.

---

## 📖 Documentation

| Doc | Description |
|---|---|
| [Architecture](docs/architecture.md) | Full system design |
| [UI Flow](docs/ui-flow.md) | Event → UI pipeline |
| [Keybindings](docs/keybindings.md) | All keyboard shortcuts |
| [Roadmap](docs/roadmap.md) | Development phases |

---

## 🗺️ Roadmap

- [x] Phase 1 — Repo scaffolding & base Hyprland config
- [ ] Phase 2 — AGS Dynamic Island
- [ ] Phase 3 — Floating dock system
- [ ] Phase 4 — Event routing engine
- [ ] Phase 5 — One-command OS-style bootstrap

---

## 📜 License

MIT © makki
