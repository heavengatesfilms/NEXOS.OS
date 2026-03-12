# NEXUS OS

A custom cybersecurity-focused Arch Linux distribution with Hyprland tiling WM,
NEXUS aesthetic (dark bg, cyan + green palette), and a curated security toolkit.

Built by Dominic.

---

## Project Structure

```
nexus-os/
├── scripts/
│   ├── 00-base-install.sh   # Arch base, LUKS2, btrfs, GRUB
│   ├── 01-desktop.sh        # Hyprland, Waybar, apps, LazyVim
│   ├── 02-dotfiles.sh       # Deploy all configs
│   └── 03-cybersec.sh       # Full cybersec toolkit + hardening
├── configs/
│   ├── hyprland/            # hyprland.conf
│   ├── waybar/              # config.jsonc + style.css
│   ├── kitty/               # kitty.conf
│   ├── zsh/                 # .zshrc + starship.toml
│   └── nvim/                # LazyVim extras
└── docs/
    └── README.md
```

---

## Install Order

### 1. Boot from Arch ISO

Download the latest Arch ISO from https://archlinux.org/download
Write to USB: `dd if=archlinux.iso of=/dev/sdX bs=4M status=progress`

### 2. Run base install

```bash
bash scripts/00-base-install.sh
```

This sets up: partitions, LUKS2 encryption, btrfs subvolumes, base packages, GRUB, user account.

### 3. First boot — run desktop install

```bash
bash scripts/01-desktop.sh
```

This installs: Hyprland, Waybar, Kitty, LazyVim, Zsh, fonts, apps, SDDM.

### 4. Deploy configs

```bash
bash scripts/02-dotfiles.sh
```

### 5. Install cybersecurity tools

```bash
bash scripts/03-cybersec.sh
```

---

## Key Bindings (Hyprland)

| Key                       | Action                   |
| ------------------------- | ------------------------ |
| `Super + Enter`           | Open terminal (Kitty)    |
| `Super + Shift + Enter`   | Floating terminal        |
| `Super + Space`           | App launcher (Rofi)      |
| `Super + Q`               | Close window             |
| `Super + F`               | Fullscreen               |
| `Super + H/J/K/L`         | Move focus               |
| `Super + Shift + H/J/K/L` | Move window              |
| `Super + 1-9`             | Switch workspace         |
| `Super + Shift + 1-9`     | Move window to workspace |
| `Super + L`               | Lock screen              |
| `Super + B`               | Browser                  |

---

## Design System

| Token        | Value                   |
| ------------ | ----------------------- |
| Background   | `#020609`               |
| Cyan accent  | `#00c8f0`               |
| Green accent | `#00ff9d`               |
| Red alert    | `#ff4060`               |
| Yellow warn  | `#f0c000`               |
| Text         | `#b0d8e8`               |
| Font (UI)    | Orbitron                |
| Font (Code)  | JetBrainsMono Nerd Font |

---

## Cybersecurity Toolkit

| Category  | Tools                                      |
| --------- | ------------------------------------------ |
| Network   | nmap, wireshark, tcpdump, netcat, masscan  |
| Web       | ffuf, gobuster, sqlmap, nikto, feroxbuster |
| Exploit   | metasploit, gdb, pwndbg, pwntools          |
| Password  | hashcat, john, hydra                       |
| Forensics | ghidra, binwalk, volatility3, exiftool     |
| Wireless  | aircrack-ng, bettercap                     |
| Privacy   | wireguard, tor, dnscrypt-proxy             |

---

## License

MIT — open source, fork it, make it yours.
