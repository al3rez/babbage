{ pkgs, ... }:

{
  # dunst: one line at a time inside the centre of the menu bar (i3 starts it)
  xdg.configFile."dunst/dunstrc".source = ../files/dunst/dunstrc;

  # dunst answers org.freedesktop.Notifications (user dir wins over system files)
  xdg.dataFile."dbus-1/services/org.freedesktop.Notifications.service".text = ''
    [D-BUS Service]
    Name=org.freedesktop.Notifications
    Exec=${pkgs.dunst}/bin/dunst
  '';

  # keep XFCE's own notifier from starting
  xdg.configFile."autostart/xfce4-notifyd.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';
}
