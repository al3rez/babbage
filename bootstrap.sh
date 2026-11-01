#!/usr/bin/env bash
# One-shot setup on a fresh Debian 13 (trixie):
#   ./bootstrap.sh            # this machine (NVIDIA)
#   ./bootstrap.sh al3rez-vm  # anything else (Mesa GL, no NVIDIA monitor layout)
set -euo pipefail

profile="${1:-al3rez}"
here="$(cd "$(dirname "$0")" && pwd)"

# 1. Debian side: the XFCE desktop, the panel plugins the bar uses (genmon shows the
#    workspace numbers), and Grok Bot from Cursor's apt repo (its package keeps this
#    source and key up to date afterwards)
sudo install -Dm644 "$here/files/apt/grok-bot.gpg" /usr/share/keyrings/grok-bot.gpg
sudo tee /etc/apt/sources.list.d/grok-bot.sources >/dev/null <<'EOF'
Types: deb
URIs: https://downloads.cursor.com/aptrepo
Suites: grok-bot
Components: main
Signed-By: /usr/share/keyrings/grok-bot.gpg
EOF
# Tailscale from its own repo: tailscaled is a system service, so it lives on the Debian side
sudo install -Dm644 "$here/files/apt/tailscale.gpg" /usr/share/keyrings/tailscale-archive-keyring.gpg
sudo tee /etc/apt/sources.list.d/tailscale.sources >/dev/null <<'EOF'
Types: deb
URIs: https://pkgs.tailscale.com/stable/debian
Suites: trixie
Components: main
Signed-By: /usr/share/keyrings/tailscale-archive-keyring.gpg
EOF
# Debian's Thailand mirror: ~2x deb.debian.org from Bangkok (measured); security stays upstream
for f in /etc/apt/sources.list /etc/apt/sources.list.d/debian.sources; do
  [ -f "$f" ] && sudo sed -Ei 's#https?://deb\.debian\.org/debian(/?)( |$)#http://ftp.th.debian.org/debian\1\2#' "$f"
done
sudo apt-get update
sudo apt-get install -y \
  curl xz-utils dbus-x11 xfconf \
  xfce4 xfce4-goodies xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin xfce4-genmon-plugin \
  blueman network-manager-gnome firefox-esr grok-bot tailscale
if [ "$profile" = "al3rez" ]; then
  sudo apt-get install -y nvidia-settings
  # driver-level monitor layout + soft DPMS (monitors stay connected while asleep);
  # takes effect at the next login
  sudo install -Dm644 "$here/files/xorg/20-nvidia-desk.conf" /etc/X11/xorg.conf.d/20-nvidia-desk.conf
fi
sudo systemctl enable --now tailscaled
sudo tailscale set --operator="$USER" --ssh   # no sudo needed for tailscale; Tailscale SSH on

# 2. Nix (flakes enabled by the Determinate installer)
if ! command -v nix >/dev/null 2>&1; then
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
fi
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# 3. Everything else: i3, picom, dunst, Ghostty, Telegram, fonts, icons, wallpaper, xfconf
nix run home-manager/master -- switch -b backup --impure --flake "$here#$profile"

echo
echo "Done. Log out and back in to start the i3 + XFCE session."
tailscale status >/dev/null 2>&1 || echo "Then run 'tailscale up' once to join your tailnet."
