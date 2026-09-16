# dotfiles

Personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Packages are split by operating system:

| Directory | Contents |
| --------- | -------- |
| `common/` | Works on every OS: `bash`, `fzf`, `ghostty`, `nvim`, `ruff`, `starship`, `zed`, `zsh` |
| `linux/`  | Arch Linux + Hyprland/Wayland: `hypr`, `quickshell`, `rofi`, `walker`, `waybar`, `wlogout` |
| `macos/`  | macOS: `aerospace`, `karabiner`, `sketchybar`, `skhd`, `zsh-macos` |
| `install/` | Installer support: `lib/helpers.sh`, `linux/pkgs.txt` (pacman/yay), `macos/Brewfile` |

Cross-platform tools live in `common/` even when only one OS currently uses
them heavily — `zsh` and `ghostty` are configured identically on Linux and
macOS. Where a shared tool needs an OS-specific add-on, that add-on gets its
own package next to the shared one: `macos/zsh-macos` only ships the
`.zprofile` that puts Homebrew on `PATH`, while `common/zsh` holds the
`.zshrc` and the plugin submodules used by both systems.

Quickshell
----------

`linux/quickshell` is the notification daemon and the quick settings panels.
It replaces `mako`, and the `ghostty -e <tui>` launchers that used to hang off
the waybar modules. The bar itself is still waybar.

    ~/.config/quickshell/
    ├── shell.qml                     entry point
    ├── Theme.qml                     Rosé Pine Moon tokens
    ├── services/Notifs.qml           notification server, history, DND
    ├── services/Panels.qml           which panel is open
    ├── modules/notifications/        popups + history center
    ├── modules/panels/               audio, network and bluetooth panels
    └── widgets/                      shared slider and button

Everything is driven over IPC, because waybar is a separate process:

| Trigger | Command |
| ------- | ------- |
| waybar audio module | `qs ipc call panels toggle audio` |
| waybar network module | `qs ipc call panels toggle network` |
| waybar bluetooth module | `qs ipc call panels toggle bluetooth` |
| `SUPER ALT CTRL SHIFT + N` | `qs ipc call notifs toggleCenter` |
| `SUPER SHIFT + N` | `qs ipc call notifs toggleDnd` |

The TUIs stay installed as a fallback for what the panels do not cover
(per-stream routing, codecs, pairing edge cases): middle click the audio module
for `wiremix`, right click the bluetooth module for `bluetui`, right click the
network module for `nmtui`.

### Wifi moved to NetworkManager

`Quickshell.Networking` only implements a NetworkManager backend — its
`NetworkBackendType` enum knows `None` and `NetworkManager`, nothing else — so
the network panel needs NetworkManager running. This setup used bare `iwd`
through `impala` before.

The migration keeps `iwd`: NetworkManager is installed in front of it and
configured to use it as the wifi backend via
`install/linux/networkmanager/wifi-backend-iwd.conf`, which `install.sh` drops
into `/etc/NetworkManager/conf.d/`. The known networks under `/var/lib/iwd`
therefore keep working, and `wpa_supplicant` is not involved.

`impala` is gone from `pkgs.txt` because it talks to iwd directly and would
fight NetworkManager over the same device.

`org.freedesktop.Notifications` can only be owned by one process. `install.sh`
masks `mako.service` if mako is still installed, otherwise dbus can activate it
and one of the two loses the name.

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
    stow -d common -t ~ --dotfile ghostty nvim zsh

    # plus the ones for your OS
    stow -d linux -t ~ --dotfile hypr waybar
    stow -d macos -t ~ --dotfile aerospace skhd zsh-macos

Make sure `~/.config` exists first (`mkdir -p ~/.config`). Otherwise stow
turns it into a symlink to the first package's `dot-config`, and stowing from
a second directory afterwards fails with a conflict.

Install stow itself, if needed:

    Arch:     pacman -S stow
    macOS:    brew install stow

### Homebrew only

    brew bundle --file=~/dotfiles/install/macos/Brewfile
    brew bundle --force cleanup --file=~/dotfiles/install/macos/Brewfile
