# Keybindings Reference

> **Legend:** `S` = Super (Meta/Win), `C` = Ctrl, `SH` = Shift, `A` = Alt

---

## 🪟 Window Management

| Keybind | Action |
|---|---|
| `S + Q` | Kill active window |
| `S + SH + Q` | **Power menu** (lock/sleep/reboot/shutdown) |
| `S + CTRL + SH + Q` | Force exit Hyprland |
| `S + F` | Fullscreen (cover bar) |
| `S + SH + F` | Fullscreen (maximize) |
| `S + Space` | Toggle floating |
| `S + P` | Toggle pseudo-tiling (Dwindle) |
| `S + T` | Toggle split direction (Dwindle) |

---

## 🧭 Focus

| Keybind | Action |
|---|---|
| `S + H / ←` | Focus left |
| `S + L / →` | Focus right |
| `S + K / ↑` | Focus up |
| `S + J / ↓` | Focus down |

---

## 🗂️ Window Movement

| Keybind | Action |
|---|---|
| `S + SH + H / ←` | Move window left |
| `S + SH + L / →` | Move window right |
| `S + SH + K / ↑` | Move window up |
| `S + SH + J / ↓` | Move window down |

---

## ↔️ Resize

| Keybind | Action |
|---|---|
| `S + CTRL + H` | Shrink width |
| `S + CTRL + L` | Grow width |
| `S + CTRL + K` | Shrink height |
| `S + CTRL + J` | Grow height |

---

## 🖥️ Workspaces

| Keybind | Action |
|---|---|
| `S + 1–9` | Switch to workspace 1–9 |
| `S + 0` | Switch to workspace 10 |
| `S + SH + 1–9` | Move window to workspace 1–9 |
| `S + scroll ↑/↓` | Cycle workspaces |
| `S + S` | Toggle scratchpad |
| `S + SH + S` | Move window to scratchpad |

---

## 🚀 Apps

| Keybind | Action |
|---|---|
| `S + Return` | Terminal (kitty) |
| `S + B` | Browser (firefox) |
| `S + E` | File manager (thunar) |
| `S + R` | App launcher (wofi → rofi → AGS) |
| `S + SH + C` | Color picker (hyprpicker) |
| `S + V` | Clipboard history (cliphist + wofi) |

---

## 🔔 Notifications

| Keybind | Action |
|---|---|
| `S + N` | Toggle notification center (swaync) |
| `S + SH + N` | Toggle Do Not Disturb |

---

## 🎨 Themes

| Keybind | Action |
|---|---|
| `S + A + 1` | Switch to **Catppuccin Mocha** (dark) |
| `S + A + 2` | Switch to **Catppuccin Latte** (light) |
| `S + A + 3` | Switch to **Catppuccin Frappé** (dark) |
| `S + A + 4` | Switch to **Catppuccin Macchiato** (dark) |

---

## 📷 Screenshots

| Keybind | Action |
|---|---|
| `Print` | Region screenshot → clipboard |
| `SH + Print` | Full screen → file (~/Pictures/Screenshots/) |
| `S + Print` | Full screen → clipboard |

---

## 🎵 Media

| Keybind | Action |
|---|---|
| `XF86AudioRaiseVolume` | Volume up (+ island expand) |
| `XF86AudioLowerVolume` | Volume down (+ island expand) |
| `XF86AudioMute` | Toggle mute |
| `XF86MonBrightnessUp` | Brightness up |
| `XF86MonBrightnessDown` | Brightness down |
| `XF86AudioPlay` | Play/Pause (+ media island) |
| `XF86AudioNext` | Next track (+ media island) |
| `XF86AudioPrev` | Previous track (+ media island) |

---

## 🔒 Lock / Power

| Keybind | Action |
|---|---|
| `S + CTRL + A + L` | Lock screen immediately |
| `S + SH + Q` | Power menu overlay |

---

## 🔧 Developer

| Keybind | Action |
|---|---|
| `S + SH + R` | Rebuild CSS + AGS hot-reload |
| `S + A + R` | Restart AGS |

---

## 🖱️ Mouse

| Keybind | Action |
|---|---|
| `S + LMB drag` | Move window |
| `S + RMB drag` | Resize window |
| `S + scroll` | Switch workspace |

---

## Power Menu Actions

> Triggered with `S + SH + Q`. Destructive actions require **two clicks**.

| Button | Action | Confirm required |
|---|---|---|
| 🔒 Lock | `loginctl lock-session` | No |
| 💤 Sleep | `systemctl suspend` | No |
| 🚪 Logout | `hyprctl dispatch exit` | **Yes** |
| 🔄 Reboot | `systemctl reboot` | **Yes** |
| ⏻ Shutdown | `systemctl poweroff` | **Yes** |
