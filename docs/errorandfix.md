# List of all error and fix 

## 1. swww Command Renamed to awww

### Error / Issue
The wallpaper utility daemon (`swww-daemon`) and cli tool (`swww`) fail to run or cause errors during boot or theme-switching because the command has been renamed by the developer to `awww`.

### Affected Files
- `config/hypr/autostart.conf`
- `scripts/system/theme-switch.sh`
- `scripts/bootstrap/packages.sh`
- `scripts/bootstrap/init.sh`
- `install.sh`
- `tools/debug/health-check.sh`
- `assets/wallpapers/README.md`
- `CHANGELOG.md`

### Fix
Replaced all occurrences of `swww` and `swww-daemon` with `awww` and `awww-daemon` respectively across all scripts, system installation commands, health check processes, configurations, and documentation.

---

## 2. Dynamic Hardware & VM Boot Environment (NVIDIA, VirtualBox, Intel/AMD)

### Issue / Feature
Running the Hyprland rice across different platforms (VirtualBox VM, Nvidia GPUs, AMD/Intel native graphics) requires different rendering settings and cursor options. Hardcoding NVIDIA environment variables prevents VirtualBox or native AMD/Intel environments from booting properly (resulting in black screens, crashed compositors, or invisible cursors).

### Solution
Created a dynamic hardware detection script: `scripts/system/detect-hw.sh`. 
It detects the environment on startup/installation and writes the correct environment overrides to `~/.config/hypr/hw-env.conf`, which is sourced inside `config/hypr/env.conf`.

### Installation / Bootstrap Override Parameters
You can force a specific hardware profile during installation or bootstrap by passing the corresponding flag:

```bash
# Force NVIDIA proprietary graphics profile
bash bootstrap.sh --nvidia
# or
bash install.sh --nvidia

# Force VM (VirtualBox/QEMU) profile
bash bootstrap.sh --vm
# or
bash install.sh --vm

# Force Intel/AMD native open-source graphics profile
bash bootstrap.sh --intel-amd
# or
bash install.sh --intel-amd

# Auto-detect (default) - Prompts for user verification when running in an interactive terminal
bash bootstrap.sh --auto
```

### Auto-Detection Verification Prompt
When using `--auto` or letting the scripts auto-detect the hardware, if the installer is run in an interactive terminal (`tty`), it will prompt:
`Detected hardware/VM: [NVIDIA GPU / VM / Intel/AMD]. Is this correct? [Y/n]:`
- **Yes (default/Enter)**: Proceeds to write the detected profile to `hw-env.conf`.
- **No (n)**: Spawns an interactive selection menu where you can manually override and choose the correct setup.
### VM Rendering Overrides for Kitty & GTK4 Applications
When booting Hyprland inside a VirtualBox virtual machine, hardware-accelerated rendering can fail and cause critical applications like `kitty` and GTK4 apps (like `ags`) to crash or fail to draw.
To resolve this, the VM overrides write-out has been enhanced:
- **Kitty / GLES rendering**: Force software-assisted GL backend rendering via `WLR_RENDERER=pixman` and `LIBGL_ALWAYS_SOFTWARE=1`.
- **GTK4 / AGS rendering**: Force GTK to use the `cairo` rendering engine via `GSK_RENDERER=cairo` to prevent GTK rendering crashes on software rasterizers.

---

## 3. Package Compatibility Issues

### 3a. `hyprpaper` conflicts with `awww`
- **Error**: Both `hyprpaper` and `awww` are wallpaper daemons. Having both installed causes conflicts since the rice exclusively uses `awww-daemon`.
- **Fix**: Removed `hyprpaper` from `ARCH_CORE` in `packages.sh`.

### 3b. `hyprpicker` — unused in this rice
- **Error**: `hyprpicker` (color picker) was in the core package list but has no associated keybindings or scripts in the rice.
- **Fix**: Removed `hyprpicker` from `ARCH_CORE` in `packages.sh`.

### 3c. `pipewire-audio` — meta-package causes silent PulseAudio removal
- **Error**: `pipewire-audio` is a meta-package that pulls in ALL PipeWire audio components including `pipewire-pulse`, which conflicts with and removes `pulseaudio` silently on upgrade. This can break audio on existing setups without warning.
- **Fix**: Replaced `pipewire-audio` with explicit packages `pipewire-pulse` + `pipewire-alsa` in both `packages.sh` and `install.sh`.

### 3d. `install.sh` and `packages.sh` package lists out of sync
- **Error**: Running `bash install.sh` vs `bash bootstrap.sh` resulted in different packages being installed. `install.sh` was missing: `dart-sass`, `cliphist`, `playerctl`, `thunar`, `thunar-archive-plugin`, `socat`, `nm-connection-editor`, `blueman`, `bluez`, `bluez-utils`, `polkit-gnome`, `hypridle`, `hyprlock`, `noto-fonts`, `ttf-font-awesome`.
- **Fix**: Fully synced `ARCH_PACKAGES` in `install.sh` to match `packages.sh`.

### 3e. `aylurs-gtk-shell` (AGS v1) — frequent AUR build failures
- **Warning**: AGS v1 AUR builds commonly fail due to `libastal` dependency issues and GObject Introspection `.typelib` errors. AGS v1 is also legacy/unmaintained by the original author.
- **Workaround**: If `yay -S aylurs-gtk-shell` fails, try:
  ```bash
  yay -S aylurs-gtk-shell-git
  # or check AUR comments for pinned patches
  ```
- **Future**: Consider migrating to AGS v2 (`astal` framework) or alternatives like Quickshell/Fabric.

### 3f. `gtk-layer-shell` — GTK3 only, tied to AGS v1
- **Warning**: `gtk-layer-shell` is in maintenance mode (GTK3 only). If the rice migrates to AGS v2, it will need `gtk4-layer-shell` instead.
- **Current Status**: Required now for AGS v1. No action needed unless upgrading AGS.

---

## 4. AGS (Aylurs' GTK Shell) v1 vs v2 Compatibility and AUR Package Transition

### Error / Issue
The `makki-rice` configuration is built using the legacy **AGS v1 API** (utilizing monolithic global `App`/`Widget` APIs, JS imports from `resource:///com/github/Aylur/...`, and GTK3 modules). 
However, the standard AUR package `aylurs-gtk-shell` has been updated to track **AGS v2 (Astal-based)**, which represents a complete rewrite and features zero backward compatibility. Installing `aylurs-gtk-shell` will lead to boot failure and configuration parsing errors.

Furthermore, `agsv1` is packaged separately in the Arch User Repository (AUR) and installs its binary as `/usr/bin/agsv1` to avoid conflicting with AGS v2 (`/usr/bin/ags`).

### Affected Files
- `scripts/bootstrap/packages.sh`
- `install.sh`
- `config/hypr/autostart.conf`
- `Makefile`
- `scripts/hypr/reload.sh`
- `services/hyprland/event-router.sh`
- `scripts/hypr/config-check.sh`
- `scripts/ui/island.sh`
- `scripts/ui/dock.sh`
- `scripts/ui/launcher.sh`
- `scripts/system/audio.sh`
- `scripts/system/brightness.sh`
- `scripts/system/battery.sh`
- `scripts/system/theme-switch.sh`
- `tools/dev/build-css.sh`
- `tools/debug/ags-inspector.sh`
- `tools/debug/health-check.sh`

### Fix / Resolution
1. **Dependency Update**: Changed the AUR package in `packages.sh` and `install.sh` from `aylurs-gtk-shell` to `agsv1`. Removed the fake `ags` package reference from pacman's `ARCH_PACKAGES` list.
2. **Transparent Binary Fallback**: Modified all script references and tools to look up the `agsv1` binary first, and fall back to `ags` if it's not present (allowing users who manually compiled or custom-aliased AGS v1 to still boot the rice).
3. **Process / Signal Handling**: Updated process queries (`pgrep` / `pkill`) to check for both `agsv1` and `ags` daemons during UI restart, CSS reload, and health verification checks.

---

## 5. Makefile Windows Path & Utility Failures

### Error / Issue
Running developer tasks via `make` on a Windows host shell (such as CMD or PowerShell) resulted in:
1. `CreateProcess(NULL, pwd, ...) failed` error due to the lack of a native Windows `pwd` command.
2. Interception of Unix shell `find` syntax by Windows CMD's built-in `find.exe` (which does string searching and lacks `-name` or `-exec` flags), causing access denied and file not found errors.

### Affected Files
- `Makefile`

### Fix / Resolution
1. **Directory Resolution**: Replaced the external `$(shell pwd)` command call with native GNU Make `$(CURDIR)`, which resolves the absolute project path on both Windows and Linux without spawning external processes.
2. **OS Environment Checks**: Added conditional `ifeq ($(OS),Windows_NT)` checks for shell-heavy and tool-specific recipes (like `make lint` which relies on `find` and `shellcheck`). It now prints an informative error explaining that the task requires a Unix environment (WSL, Git Bash, or Linux native) rather than crashing or running the incorrect Windows utilities.