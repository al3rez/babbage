{ pkgs, lib, desk, ... }:

{
  # Top menu bar: Ghostty + Firefox on the left, tray/volume/search/control centre/clock on
  # the right. Its ends line up with i3's 18px window gaps (end spacers + gtk.css padding).
  xfconf.settings.xfce4-panel = {
    "panels" = [ 1 ];
    "panels/dark-mode" = true;
    "panels/panel-1/position" = "p=9;x=0;y=0";
    "panels/panel-1/position-locked" = true;
    "panels/panel-1/length" = 100;
    "panels/panel-1/size" = 36;
    "panels/panel-1/icon-size" = 30;
    "panels/panel-1/background-style" = 1;
    "panels/panel-1/background-rgba" = [ 0.0 0.0 0.0 0.0 ];
    "panels/panel-1/enter-opacity" = 100;
    "panels/panel-1/leave-opacity" = 100;
    "panels/panel-1/plugin-ids" = [ 32 27 29 3 6 21 25 26 8 33 ];

    # left/right end spacers
    "plugins/plugin-32" = "separator";
    "plugins/plugin-32/style" = 0;
    "plugins/plugin-32/expand" = false;
    "plugins/plugin-33" = "separator";
    "plugins/plugin-33/style" = 0;
    "plugins/plugin-33/expand" = false;

    # pinned apps
    "plugins/plugin-27" = "launcher";
    "plugins/plugin-27/items" = [ "ghostty.desktop" ];
    "plugins/plugin-29" = "launcher";
    "plugins/plugin-29/items" = [ "firefox.desktop" ];

    # middle stretch
    "plugins/plugin-3" = "separator";
    "plugins/plugin-3/style" = 0;
    "plugins/plugin-3/expand" = true;

    # status area
    "plugins/plugin-6" = "systray";
    "plugins/plugin-6/icon-size" = 30;
    "plugins/plugin-6/square-icons" = true;
    "plugins/plugin-21" = "pulseaudio";
    "plugins/plugin-21/enable-keyboard-shortcuts" = true;
    "plugins/plugin-25" = "launcher";
    "plugins/plugin-25/items" = [ "spotlight.desktop" ];
    "plugins/plugin-26" = "launcher";
    "plugins/plugin-26/items" = [ "control-center.desktop" ];

    # clock: "Fri Oct 30  10:45 PM"
    "plugins/plugin-8" = "clock";
    "plugins/plugin-8/mode" = 2;
    "plugins/plugin-8/digital-layout" = 3;
    "plugins/plugin-8/digital-time-font" = "Inter 10";
    "plugins/plugin-8/digital-time-format" = "%a %b %-d  %-I:%M %p";

    # app menu still reachable with Super+Space (not on the bar)
    "plugins/plugin-19" = "whiskermenu";
    "plugins/plugin-19/button-icon" = "menu-grid-symbolic";
    "plugins/plugin-19/show-button-title" = false;
  };

  xdg.configFile = {
    "xfce4/panel/launcher-27/ghostty.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Type=Application
      Name=Ghostty
      Comment=A terminal emulator
      Exec=${desk.ghostty}/bin/ghostty
      Icon=com.mitchellh.ghostty
      StartupWMClass=com.mitchellh.ghostty
      Terminal=false
    '';
    "xfce4/panel/launcher-29/firefox.desktop".source = ../files/panel/launcher-29/firefox.desktop;
    "xfce4/panel/launcher-25/spotlight.desktop".source = ../files/panel/launcher-25/spotlight.desktop;
    "xfce4/panel/launcher-26/control-center.desktop".source = ../files/panel/launcher-26/control-center.desktop;
  };

  # Pick up panel changes in a running session
  home.activation.reloadPanel = lib.hm.dag.entryAfter [ "xfconfSettings" "linkGeneration" ] ''
    if ${pkgs.procps}/bin/pgrep -x xfce4-panel >/dev/null; then
      run /usr/bin/xfce4-panel -r || true
    fi
  '';
}
