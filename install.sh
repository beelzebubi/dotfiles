#!/usr/bin/env bash
# Dotfiles installer: detects the OS, installs the required packages and
# links the dotfiles into place with GNU Stow.
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

source "$DOTFILES_DIR/install/lib/helpers.sh"

# Stow packages shared by every OS.
STOW_COMMON=(bash fzf ghostty nvim ruff starship zed zsh)
# Current Hyprland/Wayland stack.
STOW_LINUX=(hypr waybar rofi walker mako wlogout)
# aerospace/skhd window management + karabiner + sketchybar.
STOW_MACOS=(aerospace karabiner sketchybar skhd)

OS=""
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
      OS_STOW_PACKAGES=("${STOW_LINUX[@]}")
      ;;
    Darwin)
      OS="macos"
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

install_arch_packages() {
  log_step "Installing packages from install/pkgs.txt"
  local pkgs_file="$DOTFILES_DIR/install/pkgs.txt"
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
  log_step "Installing packages via brew bundle"
  brew bundle --file="$DOTFILES_DIR/brew/Brewfile"
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
  local pkg="$1"
  local dry_output rel
  dry_output="$(stow -d "$DOTFILES_DIR" -t "$HOME" --dotfile -n -v "$pkg" 2>&1)" || true

  while IFS= read -r rel; do
    [[ -n "$rel" ]] && backup_conflict "$rel"
  done < <(echo "$dry_output" | grep -oE 'over existing target [^ ]+ since' | sed -E 's/^over existing target //; s/ since$//')
}

stow_package() {
  local pkg="$1"
  if [[ ! -d "$DOTFILES_DIR/$pkg" ]]; then
    log_warn "skipping $pkg (no such directory)"
    return 1
  fi

  resolve_conflicts "$pkg"

  if stow -d "$DOTFILES_DIR" -t "$HOME" --dotfile -R "$pkg"; then
    log_success "$pkg"
  else
    log_error "failed to stow: $pkg"
    return 1
  fi
}

install_dotfiles() {
  log_step "Linking dotfiles with GNU Stow"
  local packages=("${STOW_COMMON[@]}" "${OS_STOW_PACKAGES[@]}")
  local failed=()
  local pkg

  for pkg in "${packages[@]}"; do
    stow_package "$pkg" || failed+=("$pkg")
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
