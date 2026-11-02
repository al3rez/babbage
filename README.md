# tulum

Debian 13 + XFCE running i3 tiling, with a flat macOS-style menu bar, Ghostty and
notifications that slide into the bar. One command takes a fresh Debian install there,
built with a Nix Home Manager flake.

![tulum at 4K](docs/screenshot.png)

<sub>Full 3840×2160 screenshot from a fresh Debian 13 VM right after `bootstrap.sh`: Firefox, Telegram
and Ghostty tiled by i3, a notification in the bar. Below, the two top halves at 1:1 (no scaling).</sub>

| Left: workspace + pinned apps, Firefox | Right: notification in the bar, status icons, clock, Telegram |
|---|---|
| ![left half at 1:1](docs/zoom-left.png) | ![right half at 1:1](docs/zoom-right.png) |

Notifications are one line in the middle of the bar: no card, no background. picom slides them
down in and back up out (recorded in the VM at 60 fps, real speed, then 4× slower):

![notification sliding into the menu bar](docs/notification.gif)

```sh
git clone https://github.com/al3rez/tulum ~/.config/home-manager
~/.config/home-manager/bootstrap.sh              # NVIDIA machine (LG 4K + ASUS layout)
~/.config/home-manager/bootstrap.sh al3rez-vm    # anything else (Mesa)
```

After the first run, apply changes with:

```sh
home-manager switch --flake ~/.config/home-manager#al3rez
```

## What it sets up

| Area | Where |
|---|---|
| i3 instead of xfwm4 in the XFCE session, 12px gaps, no window borders (picom dims unfocused windows instead) | `modules/session.nix`, `modules/i3.nix`, `files/i3/config` |
| Top bar: i3 workspace numbers, Ghostty + Grok Bot + ChatGPT + T3 Code + Firefox left, tray / volume / search / control centre / clock right, ends aligned to i3 gaps. NVIDIA profile: one bar per monitor, each listing only its own workspaces (tray on the LG only) | `modules/panel.nix`, `files/gtk-3.0/gtk.css` |
| Workspaces belong to a monitor: 1–3 the LG, 4–6 the ASUS (`Super+N` jumps to that monitor; `Super+Ctrl+←/→` sends a window across). Each bar always shows its own three numbers, read from i3's config by `i3-ws-bar` (focused bright, other monitor's dimmer, rest dim, empty faint, urgent red; click to switch) | `files/i3/config`, `modules/i3.nix`, `files/bin/i3-ws-bar` |
| Grok Bot (Cursor's apt repo), ChatGPT with Codex (OpenAI's official .deb, which adds its signed apt repo for updates) and T3 Code nightly (GitHub, digest-checked), installed in the background; pinned on the bar with matching macOS squircle icons (`files/bin/make-app-icon` fits any app's artwork into Grok Bot's squircle) | `files/bin/install-desktop-apps`, `files/icons/hicolor/`, `modules/panel.nix` |
| 144 DPI, Inter, WhiteSur-Mac icons, cursor 36 | `modules/xfce.nix`, `modules/theme.nix` |
| picom: macOS-style 15px rounded window corners (10pt at 1.5x), every unfocused window dimmed, transparent bar, no shadows, notification slide | `modules/compositor.nix`, `files/picom/picom.conf` |
| dunst: one line in the centre of the bar, slides in/out | `modules/notifications.nix`, `files/dunst/dunstrc` |
| Ghostty: Berkeley Mono (TX-02), size 10, padding, Superlogical tabs, terminfo | `modules/ghostty.nix`, `files/ghostty/` |
| Telegram Desktop with tray icon sized to match | `modules/packages.nix`, `files/icons/WhiteSur-Mac/` |
| Wallpaper (wallhaven gp7mq3, hash-pinned) | `home.nix` |
| Bash prompt | `modules/shell.nix`, `files/bash/prompt.sh` |
| Tailscale (official apt repo, daemon enabled, user is operator, Tailscale SSH on; run `tailscale up` once per machine) | `bootstrap.sh`, `files/apt/tailscale.gpg` |
| Power: monitors off after 10 idle minutes, system never sleeps (`caffeine` user service holds a logind sleep block) | `modules/power.nix` |
| LG 4K@240 + ASUS MB16FC at its native 1920x1200@75 (no driver scaling, bottom edges aligned), set in the driver itself (`MetaModes`) with soft DPMS (`HardDPMS false`: sleeping monitors stay connected, so the layout is never lost); installed to `/etc/X11/xorg.conf.d/` by `bootstrap.sh` | `files/xorg/20-nvidia-desk.conf` (NVIDIA profile only) |
| `monitor-layout-guard`: keeps each bar on its own monitor (i3 docks a bar on whichever monitor it maps on, so after the panel re-maps one it can land on the wrong screen; the guard moves it back within seconds, restarting the panel only if that fails) and re-applies the layout after a replug, but only while the monitors are on and you have used them in the last minute. Never forces a driver probe, backs off on failure, logs to `journalctl -t monitor-layout-guard` | `modules/monitors.nix`, `files/bin/monitor-layout-guard` |

## Moving this machine onto the flake

The live desktop was set up by hand first; a few of those pieces would shadow or duplicate the Nix ones, so remove them before the first switch:

```sh
rm -f ~/.local/bin/ghostty ~/.local/bin/telegram                  # AppImage / tarball launchers
rm -f ~/.local/bin/i3-ws-bar                                      # now a Nix store script
rm -f ~/.local/share/applications/com.mitchellh.ghostty.desktop
rm -f ~/.config/autostart/picom.desktop                           # i3 starts picom now
rm -rf ~/.local/share/fonts/NerdFontsSymbolsOnly ~/.local/share/fonts/Inter  # Nix ships both
./bootstrap.sh
```

Home Manager moves any other existing file it takes over to `*.backup`.

Not in the repo: Berkeley Mono is a paid font, so `font-family = TX-02` only works once its
files are in `~/.local/share/fonts/BerkeleyMono-TX-02/`; without them Ghostty uses its default font.

The genmon slot files (`~/.config/xfce4/panel/genmon-*.rc`) are copied, not linked: the panel
writes plugin settings back on exit, so the switch stops the panel, replaces them, and starts it
again. Editing them by hand needs the same order (`xfce4-panel -q`, edit, `xfce4-panel &`).

## Tested

Fresh Debian 13 (trixie) VM, `task-xfce-desktop`, then `./bootstrap.sh al3rez-vm`: i3 session,
transparent bar, wallpaper, Ghostty tabs + prompt, Telegram tray icon, centred notification, picom
all come up on first login.

## If the screen ever stays black

Nothing should cause this any more, but to recover without powering off:

- `Ctrl+Alt+F3`, log in, then `sudo systemctl restart gdm` (restarts the graphical session)
- or from another machine: `ssh al3rez` over Tailscale, same command
- if a new X config is the cause: `sudo rm /etc/X11/xorg.conf.d/20-nvidia-desk.conf` first
