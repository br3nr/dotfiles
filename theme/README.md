# Desktop themes

Themes are complete desktop compositions. `appearance` is only a compatibility
hint for applications that understand light/dark; it does not imply that a
theme has another variant.

## Commands

```sh
~/.config/theme/switch-theme.sh list
~/.config/theme/switch-theme.sh current
~/.config/theme/switch-theme.sh apply daylight
~/.config/theme/switch-theme.sh nocturne
~/.config/theme/switch-theme.sh toggle
~/.config/theme/switch-theme.sh auto
```

The old `light` and `dark` commands remain aliases for the scheduled day and
night themes configured in `config.json`.

## Adding a theme

Copy one directory under `themes/`, give it a unique `id`, and author its four
parts:

- `theme.json`: identity, compatibility appearance, wallpaper and Quickshell
  design tokens. Terminal transparency lives in `effects.terminalOpacity`.
- `foot.ini`: terminal palette for the theme's appearance realm.
- `hyprland.conf`: variables consumed by the Hyprland configuration.
- `nvim.lua`: Neovim colorscheme and variant.

Then run `switch-theme.sh apply THEME_ID`. No manager code needs to change.

Quickshell watches the generated active manifest with an event-driven
`FileView`; it does not poll. Running Neovim instances started by this config
receive a direct reload command. Hyprland, Foot, the desktop appearance hint,
and wallpaper are updated by the manager after all component files have been
published.

Running Foot terminals receive the bundle's foreground, background, alpha,
cursor, and 16 ANSI colors using Foot's supported OSC control sequences. This
avoids its two-slot light/dark limitation and allows arbitrary named palettes.
