#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-toggle}"
STATE_DIR="$HOME/.config/theme"
STATE_FILE="$STATE_DIR/current"

mkdir -p "$STATE_DIR"

current_mode() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "dark"
    fi
}

resolve_mode() {
    case "$MODE" in
        light|dark)
            echo "$MODE"
            ;;
        toggle)
            if [ "$(current_mode)" = "light" ]; then
                echo "dark"
            else
                echo "light"
            fi
            ;;
        *)
            echo "Usage: $0 [light|dark|toggle]" >&2
            exit 1
            ;;
    esac
}

NEXT_MODE="$(resolve_mode)"
printf '%s\n' "$NEXT_MODE" > "$STATE_FILE"

if [ "$NEXT_MODE" = "light" ]; then
    ln -sfn "$HOME/.config/foot/themes/rose-pine-dawn.ini" "$HOME/.config/foot/theme.ini"
    cat > "$HOME/.config/nvim/lua/theme/current.lua" <<'EOF'
return {
  name = "rose-pine",
  flavour = "dawn",
  background = "light",
}
EOF
    sed -i 's/property string variant: "dark"/property string variant: "light"/' "$HOME/.config/quickshell/Theme.qml"
    pkill swaybg || true
    swaybg -o '*' -i "$HOME/Downloads/light_wallpaper.png" -m fill >/dev/null 2>&1 &
else
    ln -sfn "$HOME/.config/foot/themes/catppuccin-mocha.ini" "$HOME/.config/foot/theme.ini"
    cat > "$HOME/.config/nvim/lua/theme/current.lua" <<'EOF'
return {
  name = "cyberdream",
  flavour = "",
  background = "dark",
}
EOF
    sed -i 's/property string variant: "light"/property string variant: "dark"/' "$HOME/.config/quickshell/Theme.qml"
    pkill swaybg || true
    swaybg -o '*' -i "$HOME/.config/wallpapers/crosses.png" -m fill >/dev/null 2>&1 &
fi

hyprctl reload >/dev/null 2>&1 || true
killall -q quickshell || true
quickshell >/dev/null 2>&1 &

printf 'theme switched to %s\n' "$NEXT_MODE"
