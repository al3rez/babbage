{ pkgs, ... }:

{
  # size 10 (~13pt on a Mac at 1.5x), padding, Superlogical pill tabs, omp's dark colours
  xdg.configFile."ghostty/config.ghostty".source = ../files/ghostty/config.ghostty;
  xdg.configFile."ghostty/superlogical-tabs".source = ../files/ghostty/superlogical-tabs;
  xdg.configFile."ghostty/themes/omp-dark".source = ../files/ghostty/themes/omp-dark;
  xdg.configFile."ghostty/themes/omp-light".source = ../files/ghostty/themes/omp-light;
  xdg.configFile."ghostty/shaders".source = ../files/ghostty/shaders;   # custom-shader (curved CRT)

  # xterm-ghostty terminfo where ncurses looks for it (so less/htop/vim work)
  home.file.".terminfo".source = "${pkgs.ghostty.terminfo}/share/terminfo";
}
