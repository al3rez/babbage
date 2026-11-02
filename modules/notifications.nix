{ pkgs, ... }:

let
  # every notification tells files/bin/menubar-popovers which app sent it, for the dot under
  # that app's pinned icon (no-op if the daemon isn't running)
  badgeHook = pkgs.writeShellScript "menubar-badge" ''
    ${pkgs.glib.bin}/bin/gdbus call --session --dest io.github.al3rez.Menubar \
      --object-path /menubar/badges --method io.github.al3rez.Menubar.Notified "$1" >/dev/null 2>&1
    exit 0
  '';
in
{
  # dunst: one line at a time inside the centre of the menu bar (i3 starts it)
  xdg.configFile."dunst/dunstrc".text =
    builtins.replaceStrings [ "@badgehook@" ] [ "${badgeHook}" ] (builtins.readFile ../files/dunst/dunstrc);

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
