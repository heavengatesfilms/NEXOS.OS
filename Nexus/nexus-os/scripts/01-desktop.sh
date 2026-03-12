#!/bin/bash
# ============================================================
#  NEXUS OS — Desktop Install Script
#  Run this after first boot as your user (not root)
#  Installs Hyprland, Waybar, terminal stack, apps
# ============================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${CYAN}[NEXUS]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ── MIRRORS ──────────────────────────────────────────────────
setup_mirrors() {
  log "Setting up fast mirrors..."
  sudo reflector --latest 10 --sort rate --country US \
    --save /etc/pacman.d/mirrorlist
  sudo pacman -Syy
  ok "Mirrors updated"
}

# ── YAY (AUR helper) ─────────────────────────────────────────
install_yay() {
  if command -v yay &>/dev/null; then
    ok "yay already installed"
    return
  fi
  log "Installing yay AUR helper..."
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay && makepkg -si --noconfirm
  cd ~ && rm -rf /tmp/yay
  ok "yay installed"
}

# ── WAYLAND / HYPRLAND ───────────────────────────────────────
install_hyprland() {
  log "Installing Hyprland + Wayland stack..."
  sudo pacman -S --noconfirm \
    hyprland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    qt5-wayland qt6-wayland \
    polkit-kde-agent \
    waybar \
    hyprpaper \
    hyprlock \
    hypridle \
    dunst \
    wl-clipboard \
    cliphist \
    grim slurp \
    brightnessctl \
    playerctl

  # Launcher
  yay -S --noconfirm rofi-wayland

  ok "Hyprland stack installed"
}

# ── TERMINAL STACK ───────────────────────────────────────────
install_terminal() {
  log "Installing terminal stack..."
  sudo pacman -S --noconfirm \
    kitty \
    zsh \
    tmux \
    starship \
    zoxide \
    fzf \
    eza \
    bat \
    ripgrep \
    fd \
    btop \
    fastfetch \
    tree \
    unzip zip \
    jq \
    openssh

  # Zsh plugins
  yay -S --noconfirm \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    zsh-history-substring-search

  # Set zsh as default shell
  chsh -s /bin/zsh

  ok "Terminal stack installed"
}

# ── LAZYVIM / NEOVIM ─────────────────────────────────────────
install_lazyvim() {
  log "Installing LazyVim..."
  sudo pacman -S --noconfirm \
    neovim \
    nodejs npm \
    python \
    python-pip \
    go \
    lua \
    luarocks \
    gcc \
    cmake \
    make

  # Backup existing nvim config if present
  [[ -d ~/.config/nvim ]] && mv ~/.config/nvim ~/.config/nvim.bak

  # Install LazyVim starter
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git

  ok "LazyVim installed — run 'nvim' to complete plugin install"
}

# ── FONTS ────────────────────────────────────────────────────
install_fonts() {
  log "Installing fonts..."
  sudo pacman -S --noconfirm \
    ttf-jetbrains-mono-nerd \
    ttf-firacode-nerd \
    noto-fonts \
    noto-fonts-emoji \
    ttf-liberation

  yay -S --noconfirm \
    ttf-orbitron \
    ttf-share-tech-mono

  fc-cache -fv
  ok "Fonts installed"
}

# ── APPS ─────────────────────────────────────────────────────
install_apps() {
  log "Installing daily driver apps..."
  sudo pacman -S --noconfirm \
    firefox \
    thunar \
    gvfs \
    tumbler \
    mpv \
    imv \
    zathura zathura-pdf-mupdf \
    keepassxc \
    obsidian \
    networkmanager-applet \
    pavucontrol \
    blueman \
    nm-connection-editor

  yay -S --noconfirm \
    vesktop-bin \
    brave-bin

  ok "Apps installed"
}

# ── LOGIN MANAGER ────────────────────────────────────────────
install_sddm() {
  log "Installing SDDM login manager..."
  sudo pacman -S --noconfirm sddm qt6-svg
  yay -S --noconfirm sddm-sugar-dark
  sudo systemctl enable sddm
  ok "SDDM installed and enabled"
}

# ── PIPEWIRE AUDIO ───────────────────────────────────────────
setup_audio() {
  log "Enabling audio services..."
  systemctl --user enable --now pipewire pipewire-pulse wireplumber
  ok "Audio enabled"
}

# ── MAIN ─────────────────────────────────────────────────────
main() {
  clear
  echo -e "${CYAN}[NEXUS OS] Desktop Environment Setup${NC}"
  echo ""
  warn "This will install Hyprland, LazyVim, terminal tools, and apps."
  warn "Make sure you have an internet connection."
  echo ""

  setup_mirrors
  install_yay
  install_hyprland
  install_terminal
  install_lazyvim
  install_fonts
  install_apps
  install_sddm
  setup_audio

  echo ""
  ok "═══════════════════════════════════════════"
  ok "  Desktop install complete!"
  ok "  Next: run 02-dotfiles.sh to apply configs"
  ok "  Then: run 03-cybersec.sh for sec tools"
  ok "═══════════════════════════════════════════"
}

main
