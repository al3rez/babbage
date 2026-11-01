# Desktop

Debian 13 + XFCE session running i3, set up with Home Manager.

```sh
./bootstrap.sh              # this machine (NVIDIA)
./bootstrap.sh al3rez-vm    # other machines / VMs (Mesa)
```

After the first run, apply changes with:

```sh
home-manager switch --flake ~/.config/home-manager#al3rez
```

## What it sets up

| Area | Where |
|---|---|
| i3 instead of xfwm4 in the XFCE session, 12px gaps, flat 1px white borders | `modules/session.nix`, `modules/i3.nix`, `files/i3/config` |
| Top bar: i3 workspace numbers, Ghostty + Grok Bot + Firefox left, tray / volume / search / control centre / clock right, ends aligned to i3 gaps. NVIDIA profile: one bar per monitor, each listing only its own workspaces (tray on the LG only) | `modules/panel.nix`, `files/gtk-3.0/gtk.css` |
| Workspace numbers: `i3-ws-bar` listens to i3 and writes the genmon slots (focused bright, other monitor's dimmer, rest dim, urgent red; click to switch) | `modules/i3.nix`, `files/bin/i3-ws-bar` |
| Grok Bot from Cursor's apt repo, macOS-style icon | `bootstrap.sh`, `files/apt/`, `files/icons/hicolor/` |
| 144 DPI, Inter, WhiteSur-Mac icons, cursor 36 | `modules/xfce.nix`, `modules/theme.nix` |
| picom: transparent bar, square corners, no shadows, notification slide | `modules/compositor.nix`, `files/picom/picom.conf` |
| dunst: one line in the centre of the bar, slides in/out | `modules/notifications.nix`, `files/dunst/dunstrc` |
| Ghostty: Berkeley Mono (TX-02), size 10, padding, Superlogical tabs, terminfo | `modules/ghostty.nix`, `files/ghostty/` |
| Telegram Desktop with tray icon sized to match | `modules/packages.nix`, `files/icons/WhiteSur-Mac/` |
| Wallpaper (wallhaven gp7mq3, hash-pinned) | `home.nix` |
| Bash prompt | `modules/shell.nix`, `files/bash/prompt.sh` |
| Tailscale (official apt repo, daemon enabled, user is operator, Tailscale SSH on; run `tailscale up` once per machine) | `bootstrap.sh`, `files/apt/tailscale.gpg` |
| Power: monitors off after 10 idle minutes, system never sleeps (`caffeine` user service holds a logind sleep block) | `modules/power.nix` |
| LG 4K@240 + ASUS 1.5x NVIDIA layout, set in the driver itself (`MetaModes`) with soft DPMS (`HardDPMS false`: sleeping monitors stay connected, so the layout is never lost); installed to `/etc/X11/xorg.conf.d/` by `bootstrap.sh` | `files/xorg/20-nvidia-desk.conf` (NVIDIA profile only) |
| Backup: `monitor-layout-guard` re-applies the layout / re-seats the bars after a replug, only while the monitors are on and you have used them in the last minute, never forces a probe, backs off on failure, logs to `journalctl -t monitor-layout-guard` | `modules/monitors.nix`, `files/bin/monitor-layout-guard` |

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
