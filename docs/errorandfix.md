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