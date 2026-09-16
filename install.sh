#!/usr/bin/env bash
# Dotfiles installer: detects the OS, installs the required packages and
# links the dotfiles into place with GNU Stow.
#
# Repository layout:
#   common/   stow packages that work on every OS (zsh, ghostty, nvim, ...)
#   linux/    Arch + Hyprland/Wayland only
#   macos/    macOS only
#   install/  package lists (install/linux/pkgs.txt, install/macos/Brewfile)
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

source "$DOTFILES_DIR/install/lib/helpers.sh"

# Stow packages shared by every OS -> common/
STOW_COMMON=(bash fzf ghostty nvim ruff starship zed zsh)
# Arch Linux, Hyprland/Wayland stack -> linux/
STOW_LINUX=(hypr quickshell rofi walker waybar wlogout)
# aerospace/skhd window management + karabiner + sketchybar -> macos/
# zsh-macos adds the macOS-only .zprofile on top of the shared zsh package.
STOW_MACOS=(aerospace karabiner sketchybar skhd zsh-macos)

OS=""
OS_STOW_DIR=""
OS_STOW_PACKAGES=()
BACKUP_DIR=""

detect_os() {
  local kernel
  kernel="$(uname -s)"
  case "$kernel" in
    Linux)
      if ! command_exists pacman; then
        log_error "This script only supports Arch-based Linux (pacman not found)."
        exit 1
      fi
      OS="linux"
      OS_STOW_DIR="$DOTFILES_DIR/linux"
      OS_STOW_PACKAGES=("${STOW_LINUX[@]}")
      ;;
    Darwin)
      OS="macos"
      OS_STOW_DIR="$DOTFILES_DIR/macos"
      OS_STOW_PACKAGES=("${STOW_MACOS[@]}")
      ;;
    *)
      log_error "Unsupported OS: $kernel"
      exit 1
      ;;
  esac
  log_info "Detected OS: $OS"
}

init_submodules() {
  if [[ -d "$DOTFILES_DIR/.git" && -f "$DOTFILES_DIR/.gitmodules" ]]; then
    log_step "Initializing git submodules"
    git -C "$DOTFILES_DIR" submodule update --init --recursive
  fi
}

# --- Arch Linux ---------------------------------------------------------

ensure_yay() {
  if command_exists yay; then
    return
  fi
  log_step "Installing yay AUR helper"
  sudo pacman --needed --noconfirm -S base-devel git

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmp_dir"
  (cd "$tmp_dir" && makepkg -si --noconfirm)
  rm -rf "$tmp_dir"
  log_success "yay installed"
}

# org.freedesktop.Notifications can only be held by one process. quickshell
# claims it now, but dbus will happily activate a still-installed mako and one
# of the two will lose the name, so take mako out of the running first.
disable_mako() {
  command_exists mako || return 0
  log_step "Disabling mako (quickshell is the notification daemon now)"

  if systemctl --user mask mako.service &>/dev/null; then
    log_success "masked mako.service"
  else
    log_warn "could not mask mako.service - remove mako manually if notifications misbehave"
  fi

  pkill -x mako &>/dev/null || true
}

# quickshell's network panel talks to NetworkManager, which this setup did not
# run before (it used bare iwd via impala). Put NetworkManager in front but let
# it keep using iwd as its wifi backend, so the known networks already stored
# under /var/lib/iwd are not lost.
setup_networkmanager() {
  command_exists nmcli || return 0
  log_step "Configuring NetworkManager (iwd stays the wifi backend)"

  local conf_dir="/etc/NetworkManager/conf.d"
  local conf_src="$DOTFILES_DIR/install/linux/networkmanager/wifi-backend-iwd.conf"

  sudo install -Dm644 "$conf_src" "$conf_dir/wifi-backend-iwd.conf"
  log_success "$conf_dir/wifi-backend-iwd.conf"

  # iwd must keep running - NetworkManager drives it.
  sudo systemctl enable --now iwd.service &>/dev/null || true
  if sudo systemctl enable --now NetworkManager.service; then
    log_success "NetworkManager enabled"
  else
    log_error "could not enable NetworkManager - the network panel will stay empty"
  fi
}

install_arch_packages() {
  local pkgs_file="$DOTFILES_DIR/install/linux/pkgs.txt"
  log_step "Installing packages from install/linux/pkgs.txt"
  local failed=()
  local line pkg

  while IFS= read -r line || [[ -n "$line" ]]; do
    pkg="${line%%#*}"
    pkg="$(echo "$pkg" | xargs)"
    [[ -z "$pkg" ]] && continue

    if yay -Q "$pkg" &>/dev/null; then
      log_success "$pkg (already installed)"
      continue
    fi

    if yay --needed --noconfirm -S "$pkg"; then
      log_success "$pkg"
    else
      log_error "failed to install: $pkg"
      failed+=("$pkg")
    fi
  done <"$pkgs_file"

  if ((${#failed[@]})); then
    log_warn "Failed packages: ${failed[*]}"
  fi
}

# --- macOS ---------------------------------------------------------------

ensure_homebrew() {
  if command_exists brew; then
    return
  fi
  log_step "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  log_success "Homebrew installed"
}

install_macos_packages() {
  log_step "Installing packages from install/macos/Brewfile"
  brew bundle --file="$DOTFILES_DIR/install/macos/Brewfile"
}

# --- Stow ------------------------------------------------------------------

# Moves an existing (non-stow) file/dir at ~/<rel> out of the way so stow can
# take over that path.
backup_conflict() {
  local rel="$1"
  local src="$HOME/$rel"
  [[ -e "$src" || -L "$src" ]] || return 0

  if [[ -z "$BACKUP_DIR" ]]; then
    BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    log_info "Backing up conflicting files to $BACKUP_DIR"
  fi

  local dest="$BACKUP_DIR/$rel"
  mkdir -p "$(dirname "$dest")"
  mv "$src" "$dest"
  log_warn "backed up ~/$rel"
}

# Dry-runs stow for a package and backs up any real files that would
# conflict with the symlinks stow wants to create.
resolve_conflicts() {
  local stow_dir="$1" pkg="$2"
  local dry_output rel
  dry_output="$(stow -d "$stow_dir" -t "$HOME" --dotfile -n -v "$pkg" 2>&1)" || true

  while IFS= read -r rel; do
    [[ -n "$rel" ]] && backup_conflict "$rel"
  done < <(echo "$dry_output" | grep -oE 'over existing target [^ ]+ since' | sed -E 's/^over existing target //; s/ since$//')
}

stow_package() {
  local stow_dir="$1" pkg="$2"
  local label
  label="$(basename "$stow_dir")/$pkg"

  if [[ ! -d "$stow_dir/$pkg" ]]; then
    log_warn "skipping $label (no such directory)"
    return 1
  fi

  resolve_conflicts "$stow_dir" "$pkg"

  if stow -d "$stow_dir" -t "$HOME" --dotfile -R "$pkg"; then
    log_success "$label"
  else
    log_error "failed to stow: $label"
    return 1
  fi
}

# Directories that packages from more than one stow dir write into.
# If ~/.config does not exist yet, stow "folds" it into a symlink pointing at
# the first package's dot-config. A later stow run from a *different* stow dir
# (common/ vs linux/ vs macos/) does not recognise that symlink as its own and
# aborts with a conflict. Creating the directory up front keeps stow linking
# per-package subdirectories instead.
ensure_shared_target_dirs() {
  mkdir -p "$HOME/.config"
}

install_dotfiles() {
  log_step "Linking dotfiles with GNU Stow"
  local failed=()
  local pkg

  ensure_shared_target_dirs

  for pkg in "${STOW_COMMON[@]}"; do
    stow_package "$DOTFILES_DIR/common" "$pkg" || failed+=("common/$pkg")
  done

  for pkg in "${OS_STOW_PACKAGES[@]}"; do
    stow_package "$OS_STOW_DIR" "$pkg" || failed+=("$OS/$pkg")
  done

  if ((${#failed[@]})); then
    log_warn "Failed to stow: ${failed[*]}"
  fi
}

# --- Main ------------------------------------------------------------------

summary() {
  log_step "Done"
  if [[ -n "$BACKUP_DIR" ]]; then
    log_info "Conflicting files were backed up to: $BACKUP_DIR"
  fi
  if [[ "$OS" == "linux" ]] && command_exists hyprctl; then
    hyprctl reload &>/dev/null && log_info "Reloaded Hyprland" || true
  fi
}

main() {
  log_step "Dotfiles installation"
  detect_os
  init_submodules

  case "$OS" in
    linux)
      sudo -v
      ensure_yay
      install_arch_packages
      setup_networkmanager
      disable_mako
      ;;
    macos)
      ensure_homebrew
      install_macos_packages
      ;;
  esac

  if ! command_exists stow; then
    log_error "stow not found after package installation"
    exit 1
  fi

  install_dotfiles
  summary
}

main "$@"
