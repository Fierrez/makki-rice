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

# Auto-detect (default)
bash bootstrap.sh --auto
```