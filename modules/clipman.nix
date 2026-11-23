{ pkgs, ... }:

let
  # xfce4-clipman (Debian's) records the clipboard history; Super+Shift+V and the bar's clipboard
  # glyph (files/bin/menubar-popovers) open it. Its own tray icon is kept from docking
  # (files/clipman/no-tray.c), so the bar shows one clipboard, the resizable one.
  noTray = pkgs.runCommandCC "clipman-no-tray" { } ''
    mkdir -p $out/lib
    $CC -shared -fPIC -O2 -o $out/lib/clipman-no-tray.so ${../files/clipman/no-tray.c} -ldl
  '';
  # Ahead of /usr/bin on the session's PATH (modules/session.nix), so however Clipman starts
  # (its autostart entry, which it rewrites itself; the session manager restarting it; by
  # hand) it starts like this. argv[0] stays "xfce4-clipman", so the session manager's restart
  # command comes back here too.
  wrapper = pkgs.writeShellScriptBin "xfce4-clipman" ''
    export LD_PRELOAD=${noTray}/lib/clipman-no-tray.so''${LD_PRELOAD:+:$LD_PRELOAD}
    exec -a xfce4-clipman /usr/bin/xfce4-clipman "$@"
  '';
in
{
  home.packages = [ wrapper ];

  # with no tray icon to hang its menu from, Clipman's menu (xfce4-popup-clipman) opens at the pointer
  xfconf.settings.xfce4-clipman."tweaks/popup-at-pointer" = true;
}
