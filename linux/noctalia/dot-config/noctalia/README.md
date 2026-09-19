The Linux shell: Noctalia
-------------------------

`linux/noctalia` is the whole desktop shell: bar, notifications, control
center, launcher, clipboard history, wallpaper, idle handling, lock screen and
session menu. `hypr/hyprland.lua` starts it from the `hyprland.start` hook
with a single `hl.exec_cmd("noctalia")`.

| Was | Is now |
| --- | ------ |
| `waybar` + `waybar-module-pacman-updates-git` | `noctalia/bar.toml` (the update counter is still missing, see below) |
| `quickshell` popups, notification center, audio/network/bluetooth panels | notifications + control center |
| `mako` | the notification daemon in `noctalia/config.toml` |
| `wlogout` | `noctalia/session.toml` |
| `hyprpaper` | `[wallpaper]` in `noctalia/config.toml` (`hypr/hyprpaper.conf` is kept but unused) |
| `hypridle` | `noctalia/idle.toml`; the bar's caffeine widget is the old `hypridle-toggle` |
| `hyprlock` | the built-in lock screen (`hyprlock` stays installed as a fallback) |
| `rofi-wayland` | the launcher (`noctalia/launcher.toml`); `noctalia dmenu` replaces `rofi -dmenu` in scripts |
| `walker` + the elephant suite | dropped entirely - launcher providers cover it |
| `wiremix` / `bluetui` terminal popups | the control center (still on middle/right click) |

Apart from walker and elephant, nothing was deleted: the superseded configs stay
in the repository and stow again with `install.sh --legacy`.

### Custom menus

Anything that used to be a menu entry becomes a
`[shell.launcher.dmenu.entry.*]` in `noctalia/launcher.toml`: a command that
prints one candidate per line, and an `exec` that runs on the selected one.
`/f` (files) and `/th` (palette) are set up that way. Scripts that used
`rofi -dmenu` call `noctalia dmenu -p "Pick"` instead.

### Theme changes must not touch the repository

Noctalia never rewrites `~/.config/noctalia/`, and GUI changes go to
`~/.local/state/noctalia/settings.toml`, which is not stowed - so the repository
stays clean. The one way to break that is app theming: a template writes an
include into the target app's config, and every config under `common/` is a
stow symlink into this repository. So enable templates only for targets that are
not stowed (GTK, Qt), and give user templates an `output_path` outside
`~/.config`. `common/ghostty` needs no template at all - it already follows the
color-scheme preference Noctalia sets.

If a hand-written value seems ignored, look in
`~/.local/state/noctalia/settings.toml` first; it is safe to delete.

### Open points

- `builtin_ids` in `noctalia/templates.toml` is still empty: run
  `noctalia theme --list-templates` and opt in to the GTK and Qt ids.
- `[theme].mode` is `dark`. Switching to `auto` needs a `[location]` - fill in
  the commented block in `noctalia/config.toml`.
- The bar's `updates` button has no counter. That needs a Luau bar-widget
  plugin; check `noctalia msg plugins list` for an existing one first.
- Verify the config before a reload: `noctalia config validate`.

### Rollback

Comment out `hl.exec_cmd("noctalia")` in the `hyprland.start` hook in
`hypr/hyprland.lua`, re-enable the two lines above it, then:

    ./install.sh --legacy
    hyprctl reload


