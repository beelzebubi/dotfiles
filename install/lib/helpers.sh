#!/usr/bin/env bash
# Shared logging helpers for install.sh. No external dependencies.

if [[ -t 1 ]]; then
  COLOR_RESET=$'\033[0m'
  COLOR_BLUE=$'\033[1;34m'
  COLOR_GREEN=$'\033[1;32m'
  COLOR_YELLOW=$'\033[1;33m'
  COLOR_RED=$'\033[1;31m'
  COLOR_BOLD=$'\033[1m'
else
  COLOR_RESET=""
  COLOR_BLUE=""
  COLOR_GREEN=""
  COLOR_YELLOW=""
  COLOR_RED=""
  COLOR_BOLD=""
fi

log_step() {
  printf '\n%s==>%s %s%s%s\n' "$COLOR_BLUE" "$COLOR_RESET" "$COLOR_BOLD" "$1" "$COLOR_RESET"
}

log_info() {
  printf '%s  ->%s %s\n' "$COLOR_BLUE" "$COLOR_RESET" "$1"
}

log_success() {
  printf '%s  ok%s  %s\n' "$COLOR_GREEN" "$COLOR_RESET" "$1"
}

log_warn() {
  printf '%s  !!%s  %s\n' "$COLOR_YELLOW" "$COLOR_RESET" "$1"
}

log_error() {
  printf '%s  !!%s  %s\n' "$COLOR_RED" "$COLOR_RESET" "$1" >&2
}

command_exists() {
  command -v "$1" &>/dev/null
}
