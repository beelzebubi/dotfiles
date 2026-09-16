# dotfiles

Personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Packages are split by operating system:

| Directory | Contents |
| --------- | -------- |
| `common/` | Works on every OS: `bash`, `fzf`, `ghostty`, `nvim`, `ruff`, `starship`, `zed`, `zsh` |
| `linux/`  | Arch Linux + Hyprland/Wayland: `hypr`, `mako`, `rofi`, `walker`, `waybar`, `wlogout` |
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
