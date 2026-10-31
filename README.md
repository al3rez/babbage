# Desktop

Debian 13 + XFCE session running i3, set up with Home Manager.

```sh
./bootstrap.sh              # this machine (NVIDIA)
./bootstrap.sh al3rez-vm    # other machines / VMs (Mesa)
```

After the first run, apply changes with:

```sh
home-manager switch --impure --flake ~/.config/home-manager#al3rez
```

## What it sets up

| Area | Where |
|---|---|
| i3 instead of xfwm4 in the XFCE session, 12px gaps, flat 1px white borders | `modules/session.nix`, `modules/i3.nix`, `files/i3/config` |
| Top bar: Ghostty + Firefox left, tray / volume / search / control centre / clock right, ends aligned to i3 gaps | `modules/panel.nix`, `files/gtk-3.0/gtk.css` |
| 144 DPI, Inter, WhiteSur-Mac icons, cursor 36 | `modules/xfce.nix`, `modules/theme.nix` |
| picom: transparent bar, square corners, no shadows, notification slide | `modules/compositor.nix`, `files/picom/picom.conf` |
| dunst: one line in the centre of the bar, slides in/out | `modules/notifications.nix`, `files/dunst/dunstrc` |
| Ghostty: size 10, padding, Superlogical tabs, terminfo | `modules/ghostty.nix`, `files/ghostty/` |
| Telegram Desktop with tray icon sized to match | `modules/packages.nix`, `files/icons/WhiteSur-Mac/` |
| Wallpaper (wallhaven gp7mq3, hash-pinned) | `home.nix` |
| Bash prompt | `modules/shell.nix`, `files/bash/prompt.sh` |
| LG 4K@240 + ASUS 1.5x NVIDIA layout | `modules/monitors.nix` (NVIDIA profile only) |

## Moving this machine onto the flake

The live desktop was set up by hand first; a few of those pieces would shadow or duplicate the Nix ones, so remove them before the first switch:

```sh
rm -f ~/.local/bin/ghostty ~/.local/bin/telegram                  # AppImage / tarball launchers
rm -f ~/.local/share/applications/com.mitchellh.ghostty.desktop
rm -f ~/.config/autostart/picom.desktop                           # i3 starts picom now
./bootstrap.sh
```

Home Manager moves any other existing file it takes over to `*.backup`.

## Tested

Fresh Debian 13 (trixie) VM, `task-xfce-desktop`, then `./bootstrap.sh al3rez-vm`: i3 session,
transparent bar, wallpaper, Ghostty tabs + prompt, Telegram tray icon, centred notification, picom
all come up on first login.
