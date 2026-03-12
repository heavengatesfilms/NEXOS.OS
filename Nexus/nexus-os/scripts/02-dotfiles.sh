#!/bin/bash
# ============================================================
#  NEXUS OS — Dotfiles Deploy Script
#  Run after 01-desktop.sh to apply all configs
#  Uses GNU Stow for symlink management
# ============================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${CYAN}[NEXUS]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

DOTFILES_DIR="$HOME/.dotfiles"
REPO_URL="https://github.com/YOUR_USERNAME/nexus-os-dotfiles"

clone_dotfiles() {
  if [[ -d "$DOTFILES_DIR" ]]; then
    warn "Dotfiles already exist at $DOTFILES_DIR, pulling latest..."
    git -C "$DOTFILES_DIR" pull
  else
    log "Cloning dotfiles..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
  fi
}

deploy_configs() {
  log "Deploying configs with GNU Stow..."

  sudo pacman -S --noconfirm stow

  cd "$DOTFILES_DIR"

  # Create target dirs
  mkdir -p ~/.config/{hypr,waybar,kitty,nvim,rofi,starship,dunst,hypr}

  # Stow each package
  for pkg in hyprland waybar kitty zsh nvim rofi starship dunst; do
    if [[ -d "$pkg" ]]; then
      stow -v --restow --target="$HOME" "$pkg"
      ok "Deployed: $pkg"
    fi
  done
}

deploy_manual() {
  log "Deploying configs manually (no git repo yet)..."

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  CONFIGS_DIR="$(dirname "$SCRIPT_DIR")/configs"

  mkdir -p ~/.config/{hypr,waybar,kitty,zsh,nvim}

  # Hyprland
  cp -v "$CONFIGS_DIR/hyprland/hyprland.conf" ~/.config/hypr/hyprland.conf
  ok "Hyprland config deployed"

  # Waybar
  cp -v "$CONFIGS_DIR/waybar/config.jsonc" ~/.config/waybar/config.jsonc
  cp -v "$CONFIGS_DIR/waybar/style.css"    ~/.config/waybar/style.css
  ok "Waybar config deployed"

  # Kitty
  cp -v "$CONFIGS_DIR/kitty/kitty.conf" ~/.config/kitty/kitty.conf
  ok "Kitty config deployed"

  # Zsh
  cp -v "$CONFIGS_DIR/zsh/.zshrc" ~/.zshrc
  ok "Zsh config deployed"

  # Starship
  cp -v "$CONFIGS_DIR/starship/starship.toml" ~/.config/starship/starship.toml
  ok "Starship config deployed"
}

main() {
  echo -e "${CYAN}[NEXUS OS] Dotfiles Deploy${NC}"
  echo ""

  if [[ "$1" == "--git" ]]; then
    clone_dotfiles
    deploy_configs
  else
    deploy_manual
  fi

  ok "═══════════════════════════════════════════"
  ok "  Configs deployed!"
  ok "  Log out and back in, or run: hyprctl reload"
  ok "═══════════════════════════════════════════"
}

main "$@"
