#!/bin/bash
# ============================================================
#  NEXUS OS — Cybersecurity Tools Install
#  Run after base + desktop are set up
# ============================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${CYAN}[NEXUS]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ── NETWORK ──────────────────────────────────────────────────
install_network_tools() {
  log "Installing network tools..."
  sudo pacman -S --noconfirm \
    nmap \
    wireshark-qt \
    tcpdump \
    netcat \
    traceroute \
    whois \
    bind \
    masscan \
    iproute2 \
    net-tools

  # Add user to wireshark group
  sudo usermod -aG wireshark "$USER"
  ok "Network tools installed"
}

# ── WEB ──────────────────────────────────────────────────────
install_web_tools() {
  log "Installing web tools..."
  sudo pacman -S --noconfirm \
    sqlmap \
    gobuster \
    nikto \
    curl \
    httpie

  yay -S --noconfirm \
    ffuf \
    feroxbuster

  ok "Web tools installed"
}

# ── EXPLOITATION ─────────────────────────────────────────────
install_exploit_tools() {
  log "Installing exploitation tools..."
  sudo pacman -S --noconfirm \
    metasploit \
    gdb \
    pwndbg \
    python-pwntools \
    ltrace \
    strace

  ok "Exploitation tools installed"
}

# ── PASSWORD ─────────────────────────────────────────────────
install_password_tools() {
  log "Installing password tools..."
  sudo pacman -S --noconfirm \
    hashcat \
    john \
    hydra \
    crunch \
    wordlists

  # Download rockyou if not present
  if [[ ! -f /usr/share/wordlists/rockyou.txt ]]; then
    log "Downloading rockyou.txt..."
    sudo mkdir -p /usr/share/wordlists
    curl -L "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt" \
      -o /tmp/rockyou.txt
    sudo mv /tmp/rockyou.txt /usr/share/wordlists/
  fi

  ok "Password tools installed"
}

# ── FORENSICS / REVERSE ──────────────────────────────────────
install_forensics_tools() {
  log "Installing forensics and RE tools..."
  sudo pacman -S --noconfirm \
    ghidra \
    binwalk \
    foremost \
    hexedit \
    xxd \
    strings \
    file \
    exiftool

  yay -S --noconfirm \
    volatility3

  ok "Forensics tools installed"
}

# ── WIRELESS ─────────────────────────────────────────────────
install_wireless_tools() {
  log "Installing wireless tools..."
  sudo pacman -S --noconfirm \
    aircrack-ng \
    iw \
    wireless_tools \
    hostapd

  yay -S --noconfirm \
    bettercap

  ok "Wireless tools installed"
}

# ── PRIVACY ──────────────────────────────────────────────────
install_privacy_tools() {
  log "Installing privacy and VPN tools..."
  sudo pacman -S --noconfirm \
    wireguard-tools \
    tor \
    torsocks \
    openvpn \
    dnscrypt-proxy \
    gpg \
    age

  # Enable Tor
  sudo systemctl enable tor

  ok "Privacy tools installed"
}

# ── CONTAINERS ───────────────────────────────────────────────
install_containers() {
  log "Installing Docker for isolated lab environments..."
  sudo pacman -S --noconfirm docker docker-compose

  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER"

  ok "Docker installed"
}

# ── CUSTOM TOOL LAUNCHER ─────────────────────────────────────
create_tool_launcher() {
  log "Creating cybersec tool launcher..."

  mkdir -p ~/.config/nexus-tools

  cat > ~/.config/nexus-tools/tools.sh << 'EOF'
#!/bin/bash
# NEXUS OS Tool Launcher — call with: nexus-tools

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  ╔══════════════════════════════════╗"
echo "  ║     NEXUS OS — SEC TOOLKIT       ║"
echo "  ╚══════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${GREEN}[NET]${NC}  nmap, wireshark, tcpdump, nc"
echo -e "  ${GREEN}[WEB]${NC}  ffuf, gobuster, sqlmap, nikto"
echo -e "  ${GREEN}[EXP]${NC}  msf, gdb, pwndbg, pwntools"
echo -e "  ${GREEN}[PWD]${NC}  hashcat, john, hydra"
echo -e "  ${GREEN}[FOR]${NC}  ghidra, binwalk, volatility3"
echo -e "  ${GREEN}[AIR]${NC}  aircrack-ng, bettercap"
echo -e "  ${GREEN}[PRV]${NC}  tor, wireguard, dnscrypt"
echo ""
echo -e "  Type a tool name to launch it."
EOF

  chmod +x ~/.config/nexus-tools/tools.sh

  # Add alias to zshrc
  echo "" >> ~/.zshrc
  echo "# NEXUS Cybersec tools" >> ~/.zshrc
  echo "alias nexus-tools='~/.config/nexus-tools/tools.sh'" >> ~/.zshrc

  ok "Tool launcher created — run: nexus-tools"
}

# ── HARDENING ────────────────────────────────────────────────
basic_hardening() {
  log "Applying basic system hardening..."

  # Firewall
  sudo pacman -S --noconfirm ufw
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow ssh
  sudo ufw enable
  sudo systemctl enable ufw

  # Fail2ban
  sudo pacman -S --noconfirm fail2ban
  sudo systemctl enable --now fail2ban

  # Kernel hardening
  sudo tee /etc/sysctl.d/99-nexus-hardening.conf > /dev/null << 'EOF'
# NEXUS OS Kernel Hardening
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
EOF

  sudo sysctl -p /etc/sysctl.d/99-nexus-hardening.conf

  ok "Hardening applied"
}

# ── MAIN ─────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}[NEXUS OS] Cybersecurity Tools Install${NC}"
  echo ""
  warn "This installs a full cybersecurity toolkit."
  warn "Only use these tools on systems you own or have permission to test."
  echo ""

  install_network_tools
  install_web_tools
  install_exploit_tools
  install_password_tools
  install_forensics_tools
  install_wireless_tools
  install_privacy_tools
  install_containers
  create_tool_launcher
  basic_hardening

  echo ""
  ok "═══════════════════════════════════════════"
  ok "  Cybersecurity tools installed!"
  ok "  Run 'nexus-tools' to see your toolkit"
  ok "  REMINDER: Reboot to apply group changes"
  ok "═══════════════════════════════════════════"
}

main
