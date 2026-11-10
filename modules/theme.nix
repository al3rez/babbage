{ pkgs, lib, config, desk, ... }:

{
  # WhiteSur base + WhiteSur-Mac overrides (macOS-proportioned status icons, Ghostty/Telegram icons)
  xdg.dataFile."icons/WhiteSur".source = "${pkgs.whitesur-icon-theme}/share/icons/WhiteSur";
  xdg.dataFile."icons/WhiteSur-Mac".source = ../files/icons/WhiteSur-Mac;
  # macOS-style Grok Bot icon (App Store artwork on the Big Sur squircle, WhiteSur margins);
  # per-file links so other apps can still write into ~/.local/share/icons/hicolor
  xdg.dataFile."icons/hicolor" = { source = ../files/icons/hicolor; recursive = true; };
  # apps that install icons there leave an icon-theme.cache behind; GTK then trusts it and
  # can't see icons added later (Slack's), so rebuild it when one exists
  home.activation.hicolorCache = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    d="${config.xdg.dataHome}/icons/hicolor"
    if [ -f "$d/icon-theme.cache" ]; then
      run ${pkgs.gtk3}/bin/gtk-update-icon-cache -f -q -t "$d" || true
    fi
  '';

  # titleless xfwm4 theme (fallback window manager)
  home.file.".themes/NoTitle".source = ../files/themes/NoTitle;

  # panel styling: white Inter text, flat buttons, bar ends aligned to i3 gaps
  xdg.configFile."gtk-3.0/gtk.css".source = ../files/gtk-3.0/gtk.css;

  home.file."Pictures/Wallpapers/wallhaven-gp7mq3.jpg".source = desk.wallpaper;

  # no "EN" input-method icon in the tray
  dconf.settings."org/freedesktop/ibus/panel".show-icon-on-systray = false;

  # blueman's file-transfer plugin races obexd at login and fails with a D-Bus
  # "Timeout was reached"; Bluetooth file transfer isn't used here
  dconf.settings."org/blueman/general".plugin-list = [ "!TransferService" ];

  # dark mode for apps that follow GNOME's preference (GTK4/libadwaita, Chrome, Electron, and
  # anything asking the settings portal); GTK3 apps get Adwaita-dark from xsettings (modules/xfce.nix)
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Adwaita-dark";
  };
}
