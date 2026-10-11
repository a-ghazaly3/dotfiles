#!/usr/bin/env bash
#
# bootstrap.sh — set up a machine from these dotfiles.
#
#   1. Ensure Homebrew (and Xcode CLT) are present.
#   2. Install any missing CLI tools / casks.
#   3. Install oh-my-zsh if absent.
#   4. Init git submodules (e.g. the neovim config).
#   5. Stow every package so the dotfiles land in $HOME.
#
# Usage:
#   ./bootstrap.sh                 # install + symlink everything
#   ./bootstrap.sh --dry-run       # show what would happen, change nothing
#   ./bootstrap.sh --skip-tools    # only do submodules + symlinks
#   ./bootstrap.sh --adopt         # pull existing real files into packages
#   ./bootstrap.sh zsh nvim        # only stow these packages
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Config — edit these to change what gets installed
# ---------------------------------------------------------------------------
BREW_FORMULAS=(
  git stow neovim tmux yazi lazygit gh
  zoxide fzf fd ripgrep
  openjdk@17 python@3.14 node
)
BREW_CASKS=(
  ghostty
  font-symbols-only-nerd-font
)
INSTALL_OH_MY_ZSH=1

# ---------------------------------------------------------------------------
# Paths / args
# ---------------------------------------------------------------------------
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
SKIP_TOOLS=0
ADOPT=0
PACKAGES=()

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run)   DRY_RUN=1 ;;
    --skip-tools)   SKIP_TOOLS=1 ;;
    --adopt)        ADOPT=1 ;;
    -h|--help)      sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)             echo "unknown option: $1" >&2; exit 2 ;;
    *)              PACKAGES+=("$1") ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_BOLD=$'\033[1m'
else
  C_RESET=''; C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_BOLD=''
fi
step() { printf '\n%s==> %s%s\n' "$C_BOLD$C_BLUE" "$*" "$C_RESET"; }
info() { printf '    %s\n' "$*"; }
ok()   { printf '    %s%s%s\n' "$C_GREEN" "$*" "$C_RESET"; }
warn() { printf '    %s%s%s\n' "$C_YELLOW" "$*" "$C_RESET"; }
err()  { printf '    %s%s%s\n' "$C_RED" "$*" "$C_RESET" >&2; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '    [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }

brew_installed() { brew list --formula --versions "$1" >/dev/null 2>&1; }
cask_installed() { brew list --cask --versions "$1" >/dev/null 2>&1; }

ensure_brew() {
  step "Checking Homebrew"
  if have brew; then
    ok "Homebrew found: $(brew --version | head -1)"
    return
  fi
  # Common install location on Apple Silicon may not be on a non-login PATH.
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    ok "Loaded Homebrew from /opt/homebrew"
    return
  fi
  warn "Homebrew not found — installing (this may take a while)..."
  if [ "$DRY_RUN" -eq 1 ]; then
    info "[dry-run] would install Homebrew"
    return
  fi
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  have brew && ok "Homebrew installed" || { err "Homebrew install failed"; exit 1; }
}

check_xcode_clt() {
  step "Checking Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then
    ok "CLT present: $(xcode-select -p)"
  else
    warn "Xcode CLT missing. Run: xcode-select --install"
    warn "(needed to compile tools such as tree-sitter parsers)"
  fi
}

install_tools() {
  step "Installing missing CLI tools (Homebrew formulae)"
  local f
  for f in "${BREW_FORMULAS[@]}"; do
    if brew_installed "$f"; then
      info "✓ $f"
    else
      warn "+ installing $f"
      run brew install "$f"
    fi
  done

  step "Installing missing apps (Homebrew casks)"
  local c
  for c in "${BREW_CASKS[@]}"; do
    if cask_installed "$c"; then
      info "✓ $c"
    else
      warn "+ installing $c"
      run brew install --cask "$c"
    fi
  done
}

install_oh_my_zsh() {
  [ "$INSTALL_OH_MY_ZSH" -eq 1 ] || return 0
  step "Checking oh-my-zsh"
  if [ -d "$HOME/.oh-my-zsh" ]; then
    ok "oh-my-zsh present"
    return
  fi
  warn "+ installing oh-my-zsh"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "[dry-run] would clone oh-my-zsh"
    return
  fi
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
}

init_submodules() {
  step "Initialising git submodules"
  if [ ! -d "$DOTFILES_DIR/.git" ]; then
    warn "not a git checkout — skipping submodules"
    return
  fi
  ( cd "$DOTFILES_DIR" && run git submodule update --init --recursive )
  ok "submodules ready"
}

discover_packages() {
  local d name
  for d in "$DOTFILES_DIR"/*/; do
    name="$(basename "$d")"
    case "$name" in .git|.github) continue ;; esac
    PACKAGES+=("$name")
  done
}

stow_packages() {
  step "Linking dotfiles with GNU Stow"
  if ! have stow; then
    err "stow is not installed — cannot create symlinks"
    return 1
  fi

  if [ "${#PACKAGES[@]}" -eq 0 ]; then
    discover_packages
  fi

  local stow_args=(-R -v -t "$HOME" -d "$DOTFILES_DIR")
  [ "$DRY_RUN" -eq 1 ] && stow_args=(-n "${stow_args[@]}")
  [ "$ADOPT" -eq 1 ]   && stow_args+=(--adopt)

  info "packages: ${PACKAGES[*]}"
  local failed=() p
  for p in "${PACKAGES[@]}"; do
    if [ ! -d "$DOTFILES_DIR/$p" ]; then
      err "no such package: $p"; failed+=("$p"); continue
    fi
    if [ "$DRY_RUN" -ne 1 ]; then
      stow "${stow_args[@]}" "$p" && ok "stowed $p" || { err "failed: $p"; failed+=("$p"); }
    else
      stow "${stow_args[@]}" "$p" && ok "would stow $p" || { err "would fail: $p"; failed+=("$p"); }
    fi
  done

  if [ "${#failed[@]}" -gt 0 ]; then
    printf '\n'
    err "These packages could not be stowed: ${failed[*]}"
    warn "Usually caused by an existing real file at the target path."
    warn "Review the output above, then either move the file into the"
    warn "package or re-run with --adopt (careful: 'adopt' moves the"
    warn "target file into the package)."
    return 1
  fi
  return 0
}

summary() {
  step "Done"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "Dry run only — nothing was changed."
  else
    info "Open a new terminal (or 'exec zsh') to pick up the new shell config."
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  printf '%sBootstrapping dotfiles from %s%s\n' "$C_BOLD" "$DOTFILES_DIR" "$C_RESET"
  [ "$DRY_RUN" -eq 1 ] && warn "DRY-RUN mode: no changes will be made"

  if [ "$(uname -s)" != "Darwin" ]; then
    warn "This script is tuned for macOS. Continuing, but installs may differ."
  fi

  if [ "$SKIP_TOOLS" -eq 0 ]; then
    ensure_brew
    check_xcode_clt
    install_tools
  else
    step "Skipping tool installation (--skip-tools)"
  fi

  install_oh_my_zsh
  init_submodules
  stow_packages
  summary
}

main
