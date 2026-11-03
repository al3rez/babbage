{ lib, config, pkgs, desk, ... }:

let
  cfg = config.desk.monitors;
  applyLayout = pkgs.writeShellScriptBin "apply-desk-layout" (
    lib.removePrefix "#!/usr/bin/env bash\n" (builtins.readFile ../files/bin/apply-desk-layout)
  );
  guard = pkgs.writeScript "monitor-layout-guard"
    (builtins.replaceStrings [ "@python@" ] [ "${pkgs.python3.withPackages (p: [ p.xlib ])}/bin/python3" ]
      (builtins.readFile ../files/bin/monitor-layout-guard));
in
{
  options.desk.monitors.nvidia = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Apply the LG (DP-2, 4K 240Hz) + ASUS (DP-4, native 1920x1200@75) NVIDIA layout at login.";
  };

  config = lib.mkIf cfg.nvidia {
    home.packages = [ applyLayout ];

    systemd.user.services.monitor-layout-guard = {
      Unit = {
        Description = "LG (DP-2) + ASUS (DP-4) NVIDIA layout guard";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Environment = [
          "DISPLAY=:0"
          "WALLPAPER=${desk.wallpaper}"
          "APPLY_DESK_LAYOUT=${applyLayout}/bin/apply-desk-layout"
          "PATH=${lib.makeBinPath [ pkgs.feh pkgs.procps pkgs.i3 pkgs.xorg.xrandr ]}:/usr/bin:/bin"
        ];
        ExecStart = guard;
        Restart = "always";
        RestartSec = "2";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    xdg.configFile."autostart/monitors.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Monitor layout guard (systemd)
      Hidden=true
    '';

    home.activation.nvidiaDeskXorg = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      src="${../files/xorg/20-nvidia-desk.conf}"
      dest="/etc/X11/xorg.conf.d/20-nvidia-desk.conf"
      if [ -f "$dest" ] && ! ${pkgs.diffutils}/bin/cmp -s "$src" "$dest"; then
        $DRY_RUN_CMD echo "WARNING: $dest differs from home-manager — run: install-nvidia-desk-xorg"
      elif [ ! -f "$dest" ]; then
        $DRY_RUN_CMD echo "WARNING: missing $dest — run: install-nvidia-desk-xorg (once, sudo/pkexec)"
      fi
    '';
  };
}
