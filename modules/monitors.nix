{ lib, config, pkgs, desk, ... }:

let
  cfg = config.desk.monitors;
  # RandR-event-driven: reapplies the layout and re-seats the bars whenever the driver resets them
  guard = pkgs.writeScript "monitor-layout-guard"
    (builtins.replaceStrings [ "@python@" ] [ "${pkgs.python3.withPackages (p: [ p.xlib ])}/bin/python3" ]
      (builtins.readFile ../files/bin/monitor-layout-guard));
in
{
  options.desk.monitors.nvidia = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Apply the LG (DP-2, 4K 240Hz) + ASUS (DP-4, native 1920x1200) NVIDIA layout at login.";
  };

  # LG UltraGear on the left (primary, native 4K@240), ASUS MB16FC on the right at its native
  # 1920x1200 (16", no driver scaling), bottom edges aligned.
  # The driver forgets this after the monitors sleep/wake, so a guard reapplies it whenever
  # it gets reset (and sets it at login).
  config = lib.mkIf cfg.nvidia {
    xdg.configFile."autostart/monitors.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Monitor layout guard
      Exec=env WALLPAPER=${desk.wallpaper} PATH=${lib.makeBinPath [ pkgs.feh pkgs.procps ]}:/usr/bin:/bin ${guard}
      X-GNOME-Autostart-enabled=true
    '';
  };
}
