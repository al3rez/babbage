{ pkgs, ... }:

{
  # size 10 (~13pt on a Mac at 1.5x), padding, Superlogical pill tabs
  xdg.configFile."ghostty/config.ghostty".source = ../files/ghostty/config.ghostty;
  xdg.configFile."ghostty/superlogical-tabs".source = ../files/ghostty/superlogical-tabs;

  # xterm-ghostty terminfo where ncurses looks for it (so less/htop/vim work)
  home.file.".terminfo".source = "${pkgs.ghostty.terminfo}/share/terminfo";
}
