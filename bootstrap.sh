#!/usr/bin/env bash
# One-shot setup on a fresh Debian 13 (trixie):
#   ./bootstrap.sh            # the al3rez desk (NVIDIA, LG + ASUS, Bangkok)
#   ./bootstrap.sh generic    # anything else, any user (Mesa GL, no NVIDIA monitor layout)
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
# 1Password from its own repo (native app + `op` CLI; it updates through apt). Key fingerprint
# 3FEF 9748 469A DBE1 5DA7 CA80 AC2D 6274 2012 EA22, as published by 1Password. The debsig
# policy makes dpkg check the packages' own signature too, as 1Password's instructions do.
sudo install -Dm644 "$here/files/apt/1password.gpg" /usr/share/keyrings/1password-archive-keyring.gpg
sudo tee /etc/apt/sources.list.d/1password.sources >/dev/null <<'EOF'
Types: deb
URIs: https://downloads.1password.com/linux/debian/amd64
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/1password-archive-keyring.gpg
EOF
sudo install -Dm644 "$here/files/apt/1password.pol" /etc/debsig/policies/AC2D62742012EA22/1password.pol
sudo install -Dm644 "$here/files/apt/1password.gpg" /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
if [ "$profile" = "al3rez" ]; then
  # Debian's Thailand mirror: ~2x deb.debian.org from Bangkok (measured); security stays upstream
  for f in /etc/apt/sources.list /etc/apt/sources.list.d/debian.sources /etc/apt/mirrors/debian.list; do
    [ -f "$f" ] && sudo sed -Ei 's#https?://deb\.debian\.org/debian(/?)( |$)#http://ftp.th.debian.org/debian\1\2#' "$f"
  done
  sudo timedatectl set-timezone Asia/Bangkok
fi
sudo apt-get update
sudo apt-get install -y \
  curl xz-utils dbus-x11 xfconf \
  xfce4 xfce4-goodies xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin xfce4-genmon-plugin \
  blueman network-manager-gnome tailscale 1password 1password-cli
if [ "$profile" = "al3rez" ]; then
  # linux-headers-amd64 follows every kernel update, so DKMS can build the NVIDIA driver for
  # it; without it a new kernel boots with no driver and a black screen. The apt hook checks
  # the newest kernel after every apt run (builds the module, or installs missing headers in
  # the background) and GRUB boots the newest kernel that has the driver (GRUB_DEFAULT=saved).
  # If a kernel boots without the driver anyway, nvidia-kernel-autofix builds it at boot.
  sudo apt-get install -y nvidia-settings linux-headers-amd64
  sudo install -Dm755 "$here/files/bin/nvidia-kernel-check" /usr/local/sbin/nvidia-kernel-check
  sudo install -Dm644 "$here/files/apt/99nvidia-kernel-check" /etc/apt/apt.conf.d/99nvidia-kernel-check
  sudo install -Dm644 "$here/files/grub/nvidia-safe-kernel.cfg" /etc/default/grub.d/nvidia-safe-kernel.cfg
  sudo update-grub
  sudo /usr/local/sbin/nvidia-kernel-check
  sudo install -Dm644 "$here/files/systemd/nvidia-kernel-autofix.service" /etc/systemd/system/nvidia-kernel-autofix.service
  sudo systemctl daemon-reload
  sudo systemctl enable nvidia-kernel-autofix.service
  # driver-level monitor layout, soft DPMS and both outputs pinned as connected with their
  # EDIDs (monitors never drop off X when asleep or switched off); takes effect at the next login
  sudo install -Dm644 "$here/files/xorg/20-nvidia-desk.conf" /etc/X11/xorg.conf.d/20-nvidia-desk.conf
  sudo install -Dm644 -t /etc/X11/edid "$here/files/xorg/edid/lg-ultragear.bin" "$here/files/xorg/edid/asus-mb16fc.bin"
  # 24/7 server: nothing can suspend it, not even GDM's login screen (it suspends after 20 idle
  # minutes on its own, so a reboot nobody logs in after would take the machine offline)
  sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
fi
sudo systemctl enable --now tailscaled
sudo tailscale set --operator="$USER" --ssh   # no sudo needed for tailscale; Tailscale SSH on
if [ "$profile" = "al3rez" ]; then
  # Rex server for the Macs (superlogical.com/rex/docs/linux/installation): Rex's own apt repo,
  # pinned above Debian's unrelated Perl "rex"; then a personal server that starts at boot and
  # keeps running while logged out (linger). The Macs add it as ssh://$USER@<this machine>.
  curl -fsSL https://pkgs.superlogical.com/rex/install.sh | sh
  rex server install
fi

# Grok Bot, ChatGPT (with Codex) and T3 Code nightly are ~1 GB together, and Grok Bot's CDN
# crawls over some IPv4 routes (~30 KB/s vs MB/s over IPv6, measured from Bangkok), so they
# install in the background while Nix runs. Last apt step on purpose: it holds the apt lock
# until done. Progress: journalctl -fu desktop-apps-install
sudo install -Dm755 "$here/files/bin/install-desktop-apps" /usr/local/sbin/install-desktop-apps
systemctl is-active --quiet desktop-apps-install ||
  sudo systemd-run --unit=desktop-apps-install --collect /usr/local/sbin/install-desktop-apps

# 2. Nix (flakes enabled by the Determinate installer)
if ! command -v nix >/dev/null 2>&1; then
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
fi
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# 3. Everything else: i3, picom, dunst, Ghostty, Telegram, fonts, icons, wallpaper, xfconf
nix run home-manager/master -- switch -b backup --impure --flake "$here#$profile"
# OpenRGB's udev rules (from the profile it just installed): RAM SMBus + RGB controllers for
# the logged-in user, so the rgb-off service can turn the lighting off (modules/rgb.nix; this
# machine's profile only)
if [ "$profile" = "al3rez" ]; then
  sudo install -Dm644 "$HOME/.nix-profile/lib/udev/rules.d/60-openrgb.rules" /etc/udev/rules.d/60-openrgb.rules
  sudo udevadm control --reload-rules && sudo udevadm trigger
fi

echo
echo "Done. Log out and back in to start the i3 + XFCE session."
systemctl is-active --quiet desktop-apps-install && echo "Grok Bot, ChatGPT and T3 Code are still installing in the background (journalctl -fu desktop-apps-install)."
tailscale status >/dev/null 2>&1 || echo "Then run 'tailscale up' once to join your tailnet."
