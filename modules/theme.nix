{ pkgs, desk, ... }:

{
  # WhiteSur base + WhiteSur-Mac overrides (macOS-proportioned status icons, Ghostty/Telegram icons)
  xdg.dataFile."icons/WhiteSur".source = "${pkgs.whitesur-icon-theme}/share/icons/WhiteSur";
  xdg.dataFile."icons/WhiteSur-Mac".source = ../files/icons/WhiteSur-Mac;

  # titleless xfwm4 theme (fallback window manager)
  home.file.".themes/NoTitle".source = ../files/themes/NoTitle;

  # panel styling: white Inter text, flat buttons, bar ends aligned to i3 gaps
  xdg.configFile."gtk-3.0/gtk.css".source = ../files/gtk-3.0/gtk.css;

  home.file."Pictures/Wallpapers/wallhaven-gp7mq3.jpg".source = desk.wallpaper;

  # no "EN" input-method icon in the tray
  dconf.settings."org/freedesktop/ibus/panel".show-icon-on-systray = false;
}
