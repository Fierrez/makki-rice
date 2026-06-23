# =============================================================================
# Makefile — makki-rice Developer Tasks
# =============================================================================
# Usage: make <target>
#   make css          Compile SCSS → CSS + hot-reload AGS
#   make watch        Watch SCSS and auto-rebuild
#   make theme THEME= Switch theme (mocha|latte|frappe|macchiato)
#   make health       Run health check
#   make log          Tail event router log
#   make reload       Reload Hyprland config
#   make ags-restart  Kill and relaunch AGS
#   make install      Run full bootstrap
#   make dry-run      Preview bootstrap without changes
# =============================================================================

SHELL      := /bin/bash
RICE_DIR   := $(shell pwd)
THEME      ?= mocha

.PHONY: css watch theme health log reload ags-restart install dry-run \
        clean lint stats help config-check

# ─── Default ──────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  makki-rice developer tasks"
	@echo "  ──────────────────────────────────"
	@echo "  make css             Compile SCSS + hot-reload AGS"
	@echo "  make watch           Watch SCSS, auto-rebuild"
	@echo "  make theme THEME=X   Switch theme (mocha|latte|frappe|macchiato)"
	@echo "  make health          Run health check"
	@echo "  make config-check    Check for Hyprland configuration errors"
	@echo "  make log             Tail event router log (live)"
	@echo "  make stats           Event frequency stats"
	@echo "  make reload          Reload Hyprland config"
	@echo "  make ags-restart     Restart AGS"
	@echo "  make install         Run full bootstrap"
	@echo "  make dry-run         Preview bootstrap (no changes)"
	@echo ""

# ─── CSS ──────────────────────────────────────────────────────────────────────
css:
	@bash tools/dev/build-css.sh

watch:
	@bash tools/dev/build-css.sh --watch

theme:
	@echo "Switching to: $(THEME)"
	@bash scripts/system/theme-switch.sh $(THEME)

# ─── Diagnostics ─────────────────────────────────────────────────────────────
health:
	@bash tools/debug/health-check.sh

log:
	@bash tools/debug/event-log.sh live

stats:
	@bash tools/debug/event-log.sh stats

# ─── Hyprland ─────────────────────────────────────────────────────────────────
reload:
	@bash scripts/hypr/reload.sh

config-check:
	@bash scripts/hypr/config-check.sh

ags-restart:
	@pkill -x ags 2>/dev/null || true
	@sleep 0.3
	@ags &
	@echo "AGS restarted."

ags-reload-css:
	@ags -r "App.resetCss?.(); App.applyCss?.(App.configDir + '/style/main.css')" 2>/dev/null && \
		echo "AGS CSS reloaded." || echo "AGS not running."

# ─── Bootstrap ────────────────────────────────────────────────────────────────
install:
	@bash bootstrap.sh --health

dry-run:
	@bash bootstrap.sh --dry-run

# ─── Housekeeping ─────────────────────────────────────────────────────────────
clean:
	@rm -f ui-engine/ags/style/main.css
	@echo "Cleaned: main.css"

lint:
	@echo "Checking shell scripts..."
	@find scripts services tools -name "*.sh" -exec shellcheck {} + && \
		echo "All scripts OK." || echo "Lint errors found."

log-clear:
	@bash tools/debug/event-log.sh clear
