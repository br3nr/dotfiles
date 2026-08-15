#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/theme"
THEMES_DIR="$THEME_DIR/themes"
GENERATED_DIR="$THEME_DIR/generated"
CONFIG_FILE="$THEME_DIR/config.json"
STATE_FILE="$THEME_DIR/current"

mkdir -p "$GENERATED_DIR"

die() {
    printf 'theme: %s\n' "$*" >&2
    exit 1
}

setting() {
    jq -er "$1" "$CONFIG_FILE"
}

current_theme() {
    if [ -f "$STATE_FILE" ]; then
        head -n 1 "$STATE_FILE"
    else
        setting '.schedule.nightTheme'
    fi
}

theme_appearance() {
    jq -er '.appearance' "$THEMES_DIR/$1/theme.json"
}

resolve_theme() {
    local requested="$1"
    case "$requested" in
        light) setting '.schedule.dayTheme' ;;
        dark) setting '.schedule.nightTheme' ;;
        *) printf '%s\n' "$requested" ;;
    esac
}

scheduled_theme() {
    local hour day_start night_start
    hour=$((10#$(date +%H)))
    day_start=$(setting '.schedule.dayStarts')
    night_start=$(setting '.schedule.nightStarts')

    if (( hour >= day_start && hour < night_start )); then
        setting '.schedule.dayTheme'
    else
        setting '.schedule.nightTheme'
    fi
}

toggle_theme() {
    local current
    current="$(current_theme)"
    if [ -f "$THEMES_DIR/$current/theme.json" ] &&
       [ "$(theme_appearance "$current")" = "light" ]; then
        setting '.schedule.nightTheme'
    else
        setting '.schedule.dayTheme'
    fi
}

expand_home() {
    case "$1" in
        '$HOME/'*) printf '%s/%s\n' "$HOME" "${1#\$HOME/}" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

atomic_copy() {
    local source="$1" destination="$2" temporary
    temporary=$(mktemp "$GENERATED_DIR/.theme.XXXXXX")
    cp "$source" "$temporary"
    chmod 0644 "$temporary"
    mv -f "$temporary" "$destination"
}

notify_neovim() {
    local socket
    [ -n "${XDG_RUNTIME_DIR:-}" ] || return 0
    for socket in "$XDG_RUNTIME_DIR"/nvim-theme-*.sock; do
        [ -S "$socket" ] || continue
        nvim --server "$socket" --remote-send '<Cmd>lua ReloadTheme()<CR>' \
            >/dev/null 2>&1 || true
    done
}

foot_value() {
    local key="$1" palette="$2"
    awk -F= -v wanted="$key" '
        $1 == wanted {
            value = substr($0, index($0, "=") + 1)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            print value
            exit
        }
    ' "$palette"
}

foot_descendants() {
    local parent="$1" child
    while read -r child; do
        [ -n "$child" ] || continue
        printf '%s\n' "$child"
        foot_descendants "$child"
    done < <(pgrep -P "$parent" 2>/dev/null || true)
}

broadcast_foot_palette() {
    local palette="$1" opacity="$2" foreground background cursor
    local alpha_percent sequence value root pid tty index
    local -A terminals=()

    foreground=$(foot_value foreground "$palette")
    background=$(foot_value background "$palette")
    cursor=$(foot_value cursor "$palette")
    [ -n "$foreground" ] && [ -n "$background" ] || return 0

    alpha_percent=$(awk -v alpha="$opacity" 'BEGIN { printf "%.0f", alpha * 100 }')
    sequence=$'\033]10;#'"$foreground"$'\033\\'
    sequence+=$'\033]11;['"$alpha_percent"$']#'"$background"$'\033\\'

    if [ -n "$cursor" ]; then
        cursor="${cursor##* }"
        sequence+=$'\033]12;#'"$cursor"$'\033\\'
    fi

    for index in {0..7}; do
        value=$(foot_value "regular$index" "$palette")
        [ -n "$value" ] && sequence+=$'\033]4;'"$index"';#'"$value"$'\033\\'
    done
    for index in {0..7}; do
        value=$(foot_value "bright$index" "$palette")
        [ -n "$value" ] && sequence+=$'\033]4;'"$((index + 8))"';#'"$value"$'\033\\'
    done

    # Find PTYs only beneath Foot/footclient processes, then write the control
    # sequence as terminal output. Other terminal emulators are untouched.
    while read -r root; do
        [ -n "$root" ] || continue
        while read -r pid; do
            tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
            case "$tty" in
                pts/*) terminals["$tty"]=1 ;;
            esac
        done < <(printf '%s\n' "$root"; foot_descendants "$root")
    done < <(pgrep -x foot 2>/dev/null; pgrep -x footclient 2>/dev/null; true)

    for tty in "${!terminals[@]}"; do
        [ -w "/dev/$tty" ] || continue
        printf '%s' "$sequence" > "/dev/$tty" || true
    done
}

apply_theme() {
    local requested="$1" manifest bundle appearance wallpaper terminal_opacity
    local foot_component hypr_component nvim_component state_tmp

    [[ "$requested" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]] ||
        die "invalid theme id: $requested"

    bundle="$THEMES_DIR/$requested"
    manifest="$bundle/theme.json"
    [ -f "$manifest" ] || die "unknown theme: $requested"

    jq -e '
        (.id | type == "string") and
        (.name | type == "string") and
        (.appearance == "light" or .appearance == "dark") and
        (.identity.ascii | type == "string") and
        (.effects.terminalOpacity | type == "number") and
        (.effects.terminalOpacity >= 0 and .effects.terminalOpacity <= 1) and
        (.quickshell | type == "object") and
        (.quickshell as $q |
            [
                "surfaceBase", "surfaceRaised", "surfaceOverlay",
                "textPrimary", "textSecondary", "textMuted", "textDisabled",
                "accent", "onAccent",
                "stateHover", "statePressed", "stateSelected",
                "borderSubtle", "borderStrong",
                "success", "warning", "error", "info",
                "decorative", "decorativeMuted"
            ] as $colors |
            all($colors[]; $q[.] | type == "string" and test("^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$")) and
            ($q.fontFamily | type == "string") and
            all([
                $q.fontSizeSmall, $q.fontSizeNormal,
                $q.spacingXs, $q.spacingSm, $q.spacingMd, $q.spacingLg,
                $q.itemRadius, $q.animationDuration,
                $q.barHeight, $q.symbolBarHeight
            ][]; type == "number")
        ) and
        (.components | type == "object")
    ' "$manifest" >/dev/null || die "invalid manifest: $manifest"

    [ "$(jq -r '.id' "$manifest")" = "$requested" ] ||
        die "manifest id does not match directory: $requested"

    appearance=$(jq -r '.appearance' "$manifest")
    terminal_opacity=$(jq -r '.effects.terminalOpacity' "$manifest")
    wallpaper=$(expand_home "$(jq -r '.wallpaper' "$manifest")")
    foot_component=$(jq -r '.components.foot' "$manifest")
    hypr_component=$(jq -r '.components.hyprland' "$manifest")
    nvim_component=$(jq -r '.components.neovim' "$manifest")

    [ -f "$wallpaper" ] || die "wallpaper not found: $wallpaper"
    [ -f "$(expand_home "$(jq -r '.identity.ascii' "$manifest")")" ] ||
        die "ASCII identity not found"
    [ -f "$bundle/$foot_component" ] || die "missing Foot component"
    [ -f "$bundle/$hypr_component" ] || die "missing Hyprland component"
    [ -f "$bundle/$nvim_component" ] || die "missing Neovim component"

    # Prepare and atomically publish every file before notifying consumers.
    atomic_copy "$bundle/$foot_component" "$GENERATED_DIR/foot.ini"
    atomic_copy "$bundle/$hypr_component" "$HOME/.config/hypr/config/colors.conf"
    atomic_copy "$bundle/$nvim_component" "$HOME/.config/nvim/lua/theme/current.lua"
    atomic_copy "$manifest" "$GENERATED_DIR/active.json"

    # New Foot windows should start in the bundle's compatibility realm.
    sed -i "s/^initial-color-theme=.*/initial-color-theme=$appearance/" \
        "$HOME/.config/foot/foot.ini"

    state_tmp=$(mktemp "$THEME_DIR/.current.XXXXXX")
    printf '%s\n' "$requested" > "$state_tmp"
    mv -f "$state_tmp" "$STATE_FILE"

    broadcast_foot_palette "$bundle/$foot_component" "$terminal_opacity"
    notify_neovim
    hyprctl reload >/dev/null 2>&1 || true

    if command -v gsettings >/dev/null 2>&1 &&
       gsettings writable org.gnome.desktop.interface color-scheme 2>/dev/null |
           grep -qx true; then
        gsettings set org.gnome.desktop.interface color-scheme "prefer-$appearance" \
            >/dev/null 2>&1 || true
    fi

    pkill -x swaybg || true
    setsid -f swaybg -o '*' -i "$wallpaper" -m fill >/dev/null 2>&1 || true

    printf 'theme switched to %s (%s)\n' "$requested" "$appearance"
}

list_themes() {
    local manifest active marker
    active="$(current_theme)"
    for manifest in "$THEMES_DIR"/*/theme.json; do
        [ -f "$manifest" ] || continue
        marker=' '
        [ "$(jq -r '.id' "$manifest")" = "$active" ] && marker='*'
        printf '%s %-20s %s [%s]\n' \
            "$marker" \
            "$(jq -r '.id' "$manifest")" \
            "$(jq -r '.name' "$manifest")" \
            "$(jq -r '.appearance' "$manifest")"
    done
}

list_themes_json() {
    local manifests=()
    local manifest

    for manifest in "$THEMES_DIR"/*/theme.json; do
        [ -f "$manifest" ] && manifests+=("$manifest")
    done

    if [ "${#manifests[@]}" -eq 0 ]; then
        printf '[]\n'
        return
    fi

    jq -s '[.[] | {
        id,
        name,
        appearance,
        wallpaper,
        identity,
        quickshell
    }]' "${manifests[@]}"
}

COMMAND="${1:-toggle}"
case "$COMMAND" in
    apply)
        [ "$#" -eq 2 ] || die "usage: $0 apply THEME"
        apply_theme "$(resolve_theme "$2")"
        ;;
    auto)
        apply_theme "$(scheduled_theme)"
        ;;
    toggle)
        apply_theme "$(toggle_theme)"
        ;;
    list)
        list_themes
        ;;
    list-json)
        list_themes_json
        ;;
    current)
        current_theme
        ;;
    light|dark)
        apply_theme "$(resolve_theme "$COMMAND")"
        ;;
    *)
        # A bare theme id remains convenient for keybinds and the bar.
        [ "$#" -eq 1 ] || die "usage: $0 [apply THEME|THEME|auto|toggle|list|current]"
        apply_theme "$(resolve_theme "$COMMAND")"
        ;;
esac
