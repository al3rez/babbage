{ pkgs, desk, ... }:

{
  home.packages = [
    desk.ghostty
    desk.telegram
    desk.picom
    pkgs.i3
    pkgs.dunst
    pkgs.libnotify
    pkgs.feh

    # Inter is the system UI font; the Nerd Font symbols cover prompt/tab icons
    pkgs.inter
    pkgs.nerd-fonts.symbols-only
  ];

  fonts.fontconfig.enable = true;
}
