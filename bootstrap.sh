#!/usr/bin/env bash
# One-shot setup on a fresh Debian 13 (trixie):
#   ./bootstrap.sh            # this machine (NVIDIA)
#   ./bootstrap.sh al3rez-vm  # anything else (Mesa GL, no NVIDIA monitor layout)
set -euo pipefail

profile="${1:-al3rez}"
here="$(cd "$(dirname "$0")" && pwd)"

# 1. Debian side: the XFCE desktop and the panel plugins the bar uses
sudo apt-get update
sudo apt-get install -y \
  curl xz-utils dbus-x11 xfconf \
  xfce4 xfce4-goodies xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin \
  blueman network-manager-gnome firefox-esr
if [ "$profile" = "al3rez" ]; then
  sudo apt-get install -y nvidia-settings
fi

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
