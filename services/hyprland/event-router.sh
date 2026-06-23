#!/bin/bash
# =============================================================================
# services/hyprland/event-router.sh — Phase 4: Full Event Routing Engine
# =============================================================================
#
# Architecture:
#   socket2 stream → parser → dispatch table → handler functions
#                                              → AGS bridge calls
#                                              → script invocations
#                                              → notify-send
#
# Features:
#   - Full Hyprland socket2 event map (all known events)
#   - Per-event rate limiting (prevents storm flooding)
#   - Deduplication (skip repeated identical events)
#   - Structured JSON logging with rotation
#   - Graceful shutdown on SIGTERM/SIGINT
#   - AGS signal bridge (ags -r "globalThis.signal()")
#
# Docs: https://wiki.hyprland.org/IPC/
# =============================================================================

set -uo pipefail   # Note: no -e, we handle errors manually per-handler

# ─── Environment ─────────────────────────────────────────────────────────────
RICE_DIR="${HOME}/.config/makki-rice"
SOCKET="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"
LOG_DIR="${HOME}/.local/share/makki-rice/logs"
LOG_FILE="$LOG_DIR/event-router.log"
MAX_LOG_BYTES=$((2 * 1024 * 1024))   # 2 MB log rotation threshold

mkdir -p "$LOG_DIR"

# ─── Logging ─────────────────────────────────────────────────────────────────
_log_raw() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts=$(date '+%Y-%m-%dT%H:%M:%S')
    # JSON structured log
    printf '{"ts":"%s","level":"%s","msg":%s}\n' \
        "$ts" "$level" "$(printf '%s' "$msg" | jq -Rc .)" \
        >> "$LOG_FILE" 2>/dev/null || \
    printf '[%s] [%s] %s\n' "$ts" "$level" "$msg" >> "$LOG_FILE"
}

log_info()  { _log_raw "INFO"  "$*"; }
log_warn()  { _log_raw "WARN"  "$*"; }
log_error() { _log_raw "ERROR" "$*"; }
log_event() { _log_raw "EVENT" "$*"; }

rotate_log() {
    if [[ -f "$LOG_FILE" ]]; then
        local size
        size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        if (( size > MAX_LOG_BYTES )); then
            mv "$LOG_FILE" "${LOG_FILE}.1"
            log_info "Log rotated (was ${size} bytes)"
        fi
    fi
}

# ─── Rate Limiter ─────────────────────────────────────────────────────────────
# Prevents the same event flooding handlers within a cooldown window.
# Usage: rate_limit <event_key> <cooldown_seconds>
declare -A _rate_last_time=()

rate_limit() {
    local key="$1"
    local cooldown="${2:-1}"
    local now
    now=$(date +%s%N)                          # nanoseconds
    local last="${_rate_last_time[$key]:-0}"
    local diff=$(( (now - last) / 1000000 ))   # convert to ms
    local cooldown_ms=$(( cooldown * 1000 ))

    if (( diff < cooldown_ms )); then
        return 1   # rate limited
    fi

    _rate_last_time[$key]="$now"
    return 0
}

# ─── Deduplication ────────────────────────────────────────────────────────────
declare -A _last_seen=()

dedupe() {
    local key="$1"
    local val="$2"
    if [[ "${_last_seen[$key]:-}" == "$val" ]]; then
        return 1   # duplicate
    fi
    _last_seen[$key]="$val"
    return 0
}

# ─── AGS Bridge ───────────────────────────────────────────────────────────────
# Fire-and-forget AGS JS evaluation. Never blocks or fails the router.
ags_signal() {
    local js="$1"
    ags -r "$js" 2>/dev/null &
}

# Convenience wrappers
ags_island_expand()  { ags_signal "globalThis.islandExpand?.('$1', ${2:-3000})"; }
ags_island_collapse(){ ags_signal "globalThis.islandCollapse?.()"; }
ags_dock_show()      { ags_signal "globalThis.dockShow?.()"; }
ags_dock_hide()      { ags_signal "globalThis.dockHide?.()"; }
ags_notify()         { ags_signal "globalThis.routerNotify?.('$1', '$2')"; }

# ─── Notification helper ──────────────────────────────────────────────────────
notify() {
    local urgency="${1:-normal}"
    local title="$2"
    local body="${3:-}"
    local icon="${4:-dialog-information-symbolic}"
    notify-send -u "$urgency" -i "$icon" "$title" "$body" 2>/dev/null &
}

# =============================================================================
# EVENT HANDLERS
# =============================================================================

# ── Workspace ─────────────────────────────────────────────────────────────────
on_workspace() {
    local id="$1"
    dedupe "workspace" "$id" || return 0
    rate_limit "workspace" 0 || return 0
    log_event "workspace id=$id"
    # AGS updates workspace pills natively via Hyprland service hook
    # No action needed here unless adding custom logic
}

on_workspace_v2() {
    local id="$1" name="$2"
    dedupe "workspace_v2" "$id" || return 0
    log_event "workspacev2 id=$id name=$name"
}

on_focus_changed_v2() {
    local id="$1" name="$2"
    log_event "focusedmon id=$id name=$name"
}

# ── Window ────────────────────────────────────────────────────────────────────
on_active_window() {
    local class="$1" title="$2"
    dedupe "active_window" "$class|$title" || return 0
    log_event "activewindow class=$class title=$title"
}

on_active_window_v2() {
    local address="$1" class="$2" title="$3"
    dedupe "active_window_v2" "$address" || return 0
    log_event "activewindowv2 addr=$address class=$class"
}

on_fullscreen() {
    local state="$1"
    dedupe "fullscreen" "$state" || return 0
    log_event "fullscreen state=$state"

    if [[ "$state" == "1" ]]; then
        ags_dock_hide
    else
        ags_dock_show
    fi
}

on_open_window() {
    local address="$1" ws="$2" class="$3" title="$4"
    log_event "openwindow addr=$address ws=$ws class=$class"
}

on_close_window() {
    local address="$1"
    log_event "closewindow addr=$address"
}

on_move_window() {
    local address="$1" ws="$2"
    log_event "movewindow addr=$address ws=$ws"
}

on_move_window_v2() {
    local address="$1" ws_id="$2" ws_name="$3"
    log_event "movewindowv2 addr=$address ws=$ws_id"
}

on_minimize() {
    local address="$1" state="$2"  # 1=minimized 0=restored
    log_event "minimize addr=$address state=$state"
}

on_floating() {
    local address="$1" state="$2"
    log_event "changefloatingmode addr=$address floating=$state"
}

on_window_title() {
    local address="$1"
    log_event "windowtitle addr=$address"
}

on_urgent() {
    local address="$1"
    log_event "urgent addr=$address"
    # Flash the dock / notify AGS
    rate_limit "urgent" 2 || return 0
    notify "normal" "Urgent Window" "A window requires your attention."
}

# ── Layer ─────────────────────────────────────────────────────────────────────
on_layer_opened() {
    local ns="$1"
    log_event "openlayer namespace=$ns"
}

on_layer_closed() {
    local ns="$1"
    log_event "closelayer namespace=$ns"
}

# ── Submap ────────────────────────────────────────────────────────────────────
on_submap() {
    local name="$1"
    log_event "submap name=$name"
    if [[ -n "$name" ]]; then
        ags_signal "globalThis.onSubmap?.('$name')"
    fi
}

# ── Monitor ───────────────────────────────────────────────────────────────────
on_monitor_added() {
    local monitor="$1"
    log_event "monitoradded monitor=$monitor"
    rate_limit "monitor_add" 5 || return 0
    notify "low" "Monitor Connected" "$monitor"
}

on_monitor_added_v2() {
    local id="$1" name="$2" desc="$3"
    log_event "monitoraddedv2 id=$id name=$name"
    rate_limit "monitor_add_v2" 5 || return 0
    notify "low" "Monitor Connected" "$name"
}

on_monitor_removed() {
    local monitor="$1"
    log_event "monitorremoved monitor=$monitor"
    notify "normal" "Monitor Disconnected" "$monitor"
}

# ── Mouse / Input ──────────────────────────────────────────────────────────────
on_mouse_move() {
    local coords="$1"
    # Too noisy — never log, never act unless needed
    : # no-op
}

# ── Special Workspace ─────────────────────────────────────────────────────────
on_special_workspace() {
    local name="$1" state="$2"   # state: 1=opened 0=closed (inferred)
    log_event "activespecial name=$name"
}

# ── Config Reload ─────────────────────────────────────────────────────────────
on_config_reloaded() {
    log_event "configreloaded"
    rate_limit "config_reload" 3 || return 0
    notify "low" "Hyprland" "Config reloaded."
    # Reload AGS CSS
    ags_signal "App.resetCss?.(); App.applyCss?.(App.configDir + '/style/main.css')"
}

# ── Screencopy / Screencast ───────────────────────────────────────────────────
on_screencast() {
    local state="$1" owner="$2"
    log_event "screencast state=$state owner=$owner"
    if [[ "$state" == "1" ]]; then
        ags_signal "globalThis.onScreencast?.(true)"
    else
        ags_signal "globalThis.onScreencast?.(false)"
    fi
}

# ── Pin / Group ───────────────────────────────────────────────────────────────
on_pin() {
    local address="$1" state="$2"
    log_event "pin addr=$address state=$state"
}

on_group_changed() {
    local type="$1" address="$2"
    log_event "groupchanged type=$type addr=$address"
}

# =============================================================================
# DISPATCH TABLE
# =============================================================================
# Maps socket2 event names to handler functions.
# Keeping this as a central table makes it trivial to add/disable events.

dispatch() {
    local event="$1"
    local data="$2"

    case "$event" in
        # ── Workspace ──────────────────────────────────────────────────────
        workspace)
            on_workspace "$data"
            ;;
        workspacev2)
            IFS=',' read -r id name <<< "$data"
            on_workspace_v2 "$id" "${name:-}"
            ;;
        focusedmon)
            IFS=',' read -r id name <<< "$data"
            on_focus_changed_v2 "$id" "${name:-}"
            ;;
        activeworkspace)
            on_workspace "$data"
            ;;

        # ── Window ─────────────────────────────────────────────────────────
        activewindow)
            IFS=',' read -r class title <<< "$data"
            on_active_window "${class:-}" "${title:-}"
            ;;
        activewindowv2)
            # data: address,class,title (newer Hyprland)
            IFS=',' read -r addr class title <<< "$data"
            on_active_window_v2 "${addr:-}" "${class:-}" "${title:-}"
            ;;
        fullscreen)
            on_fullscreen "$data"
            ;;
        openwindow)
            IFS=',' read -r addr ws class title <<< "$data"
            on_open_window "${addr:-}" "${ws:-}" "${class:-}" "${title:-}"
            ;;
        closewindow)
            on_close_window "$data"
            ;;
        movewindow)
            IFS=',' read -r addr ws <<< "$data"
            on_move_window "${addr:-}" "${ws:-}"
            ;;
        movewindowv2)
            IFS=',' read -r addr ws_id ws_name <<< "$data"
            on_move_window_v2 "${addr:-}" "${ws_id:-}" "${ws_name:-}"
            ;;
        changefloatingmode)
            IFS=',' read -r addr state <<< "$data"
            on_floating "${addr:-}" "${state:-}"
            ;;
        windowtitle)
            on_window_title "$data"
            ;;
        minimize)
            IFS=',' read -r addr state <<< "$data"
            on_minimize "${addr:-}" "${state:-}"
            ;;
        urgent)
            on_urgent "$data"
            ;;
        pin)
            IFS=',' read -r addr state <<< "$data"
            on_pin "${addr:-}" "${state:-}"
            ;;
        windowtitlev2)
            # data: address,title
            IFS=',' read -r addr title <<< "$data"
            log_event "windowtitlev2 addr=$addr title=${title:-}"
            ;;

        # ── Layer ──────────────────────────────────────────────────────────
        openlayer)
            on_layer_opened "$data"
            ;;
        closelayer)
            on_layer_closed "$data"
            ;;

        # ── Submap ─────────────────────────────────────────────────────────
        submap)
            on_submap "$data"
            ;;

        # ── Monitor ────────────────────────────────────────────────────────
        monitoradded)
            on_monitor_added "$data"
            ;;
        monitoraddedv2)
            IFS=',' read -r id name desc <<< "$data"
            on_monitor_added_v2 "${id:-}" "${name:-}" "${desc:-}"
            ;;
        monitorremoved)
            on_monitor_removed "$data"
            ;;

        # ── Special Workspace ───────────────────────────────────────────────
        activespecial)
            IFS=',' read -r name monitor <<< "$data"
            on_special_workspace "${name:-}" "${monitor:-}"
            ;;
        createworkspace|createworkspacev2)
            log_event "createworkspace data=$data"
            ;;
        destroyworkspace|destroyworkspacev2)
            log_event "destroyworkspace data=$data"
            ;;
        moveworkspace|moveworkspacev2)
            log_event "moveworkspace data=$data"
            ;;
        renameworkspace)
            log_event "renameworkspace data=$data"
            ;;

        # ── Config ─────────────────────────────────────────────────────────
        configreloaded)
            on_config_reloaded
            ;;

        # ── Screencopy ─────────────────────────────────────────────────────
        screencast)
            IFS=',' read -r state owner <<< "$data"
            on_screencast "${state:-}" "${owner:-}"
            ;;

        # ── Groups ─────────────────────────────────────────────────────────
        groupchanged)
            IFS=',' read -r type addr <<< "$data"
            on_group_changed "${type:-}" "${addr:-}"
            ;;
        togglegroup)
            log_event "togglegroup data=$data"
            ;;
        moveintogroup|moveoutofgroup)
            log_event "$event addr=$data"
            ;;

        # ── Mouse ──────────────────────────────────────────────────────────
        mousemove)
            on_mouse_move "$data"
            ;;
        mousemoveabsolute)
            : # no-op
            ;;

        # ── Lock ───────────────────────────────────────────────────────────
        lockgroups)
            log_event "lockgroups state=$data"
            ;;

        # ── Swipe ──────────────────────────────────────────────────────────
        swipebegin|swipeupdated|swipeend)
            : # no-op — gesture events are too frequent to log
            ;;

        # ── Unknown ────────────────────────────────────────────────────────
        *)
            log_event "UNKNOWN event=$event data=$data"
            ;;
    esac
}

# =============================================================================
# MAIN LOOP
# =============================================================================

startup_check() {
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        echo "ERROR: HYPRLAND_INSTANCE_SIGNATURE not set. Is Hyprland running?"
        exit 1
    fi

    if [[ ! -S "$SOCKET" ]]; then
        echo "ERROR: Hyprland socket not found: $SOCKET"
        exit 1
    fi

    if ! command -v socat &>/dev/null; then
        echo "ERROR: socat is required but not installed."
        exit 1
    fi
}

shutdown_handler() {
    log_info "Event router received shutdown signal — stopping."
    exit 0
}

trap shutdown_handler SIGTERM SIGINT SIGHUP

main() {
    startup_check
    rotate_log
    log_info "Event router started. Socket: $SOCKET"
    log_info "Rice dir: $RICE_DIR"

    local event data line
    socat -U - "UNIX-CONNECT:$SOCKET" | while IFS= read -r line; do
        # Fast parse: everything before >> is event, after is data
        event="${line%%>>*}"
        data="${line#*>>}"

        # Skip blank lines
        [[ -z "$event" ]] && continue

        dispatch "$event" "$data"
    done

    log_info "Socket stream ended — event router exiting."
}

main "$@"
