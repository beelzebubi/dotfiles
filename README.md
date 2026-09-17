# dotfiles

Personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Packages are split by operating system:

| Directory | Contents |
| --------- | -------- |
| `common/` | Works on every OS: `bash`, `fzf`, `ghostty`, `nvim`, `ruff`, `starship`, `zed`, `zsh` |
| `linux/`  | Arch Linux + Hyprland/Wayland: `hypr`, `noctalia`, plus the superseded `quickshell`, `rofi`, `walker`, `waybar`, `wlogout` |
| `macos/`  | macOS: `aerospace`, `karabiner`, `sketchybar`, `skhd`, `zsh-macos` |
| `install/` | Installer support: `lib/helpers.sh`, `linux/pkgs.txt` (pacman/yay), `macos/Brewfile` |

Cross-platform tools live in `common/` even when only one OS currently uses
them heavily — `zsh` and `ghostty` are configured identically on Linux and
macOS. Where a shared tool needs an OS-specific add-on, that add-on gets its
own package next to the shared one: `macos/zsh-macos` only ships the
`.zprofile` that puts Homebrew on `PATH`, while `common/zsh` holds the
`.zshrc` and the plugin submodules used by both systems.

Installation
------------

Clone the repository:

    git clone --recurse-submodules https://github.com/beelzebubi/dotfiles.git ~/dotfiles

### Automatic _(recommended)_

    ~/dotfiles/install.sh

The installer detects the OS, installs the packages for it
(`install/linux/pkgs.txt` via `yay`, or `install/macos/Brewfile` via
`brew bundle`) and stows `common/` plus the matching OS directory. Existing
files that would be overwritten are moved to `~/.dotfiles-backup/<timestamp>/`.

### Manual

Stow reads one directory at a time, so pass the OS directory with `-d`:

    cd ~/dotfiles

    # shared packages
    stow -t ~ -d common -v --dotfile fzf ghostty nvim ruff starship zed zsh

    # plus the ones for your OS
    stow -t ~ -d linux -v --dotfile hypr noctalia
    stow -t ~ -d macos -v --dotfile aerospace karabiner sketchybar skhd zsh-macos

Make sure `~/.config` exists first (`mkdir -p ~/.config`). Otherwise stow
turns it into a symlink to the first package's `dot-config`, and stowing from
a second directory afterwards fails with a conflict.

Install stow itself, if needed:

    Arch:     pacman -S stow
    macOS:    brew install stow

### Homebrew only

    brew bundle --file=~/dotfiles/install/macos/Brewfile
    brew bundle --force cleanup --file=~/dotfiles/install/macos/Brewfile

The Linux shell: Noctalia
-------------------------

`linux/noctalia` is the whole desktop shell: bar, notifications, control
center, launcher, clipboard history, wallpaper, idle handling, lock screen and
session menu. `hypr/hyprland.conf` starts it with a single `exec-once =
noctalia`.

| Was | Is now |
| --- | ------ |
| `waybar` + `waybar-module-pacman-updates-git` | `noctalia/bar.toml` (the update counter is still missing, see below) |
| `quickshell` popups, notification center, audio/network/bluetooth panels | notifications + control center |
| `mako` | the notification daemon in `noctalia/config.toml` |
| `wlogout` | `noctalia/session.toml` |
| `hyprpaper` | `[wallpaper]` in `noctalia/config.toml` (`hypr/hyprpaper.conf` is kept but unused) |
| `hypridle` | `noctalia/idle.toml`; the bar's caffeine widget is the old `hypridle-toggle` |
| `hyprlock` | the built-in lock screen (`hyprlock` stays installed as a fallback) |
| `rofi-wayland` | the launcher; `noctalia dmenu` replaces `rofi -dmenu` in scripts |
| `walker` + the elephant suite | launcher providers and `noctalia/launcher.toml` |
| `wiremix` / `bluetui` terminal popups | the control center (still on middle/right click) |

Nothing was deleted: every superseded config stays in the repository and can be
stowed again with `install.sh --legacy`.

### Before switching a machine over

The 15 walker menus in `walker/dot-config/walker/config.toml` point at
definitions under `~/.config/elephant/`, which were never part of this
repository. Back them up before uninstalling anything:

    cp -r ~/.config/elephant linux/walker/dot-config/elephant

Only then port the menus worth keeping into
`[shell.launcher.dmenu.entry.*]` in `noctalia/launcher.toml`.

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

Comment out `exec-once = noctalia` in `hypr/hyprland.conf`, re-enable the three
lines above it, then:

    ./install.sh --legacy
    hyprctl reload

### Cleaning up later

Once Noctalia has run for a while, unstow the superseded packages and drop them
from `install/linux/pkgs.txt` (`waybar`, `waybar-module-pacman-updates-git`,
`rofi-wayland`, `walker`, `elephant-*`, `wlogout`, `hyprpaper`, `hypridle`,
`quickshell`). `hyprlock` and the legacy configs stay.

    stow -t ~ -d linux --dotfile -D quickshell rofi walker waybar wlogout
