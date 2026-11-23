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

    # xfsettingsd still applies Default at login even with automatic profiles disabled.
    # Keep that profile consistent; let the guard own hotplug/wake correction.
    xfconf.settings.displays = {
      AutoEnableProfiles = 0;
      Notify = 0;
      "Default/DP-2" = "LG Electronics 32\"";
      "Default/DP-2/Active" = true;
      "Default/DP-2/Primary" = true;
      "Default/DP-2/Resolution" = "3840x2160";
      "Default/DP-2/RefreshRate" = 240.084397;
      "Default/DP-2/Position/X" = 0;
      "Default/DP-2/Position/Y" = 0;
      "Default/DP-2/Rotation" = 0;
      "Default/DP-2/Reflection" = "0";
      "Default/DP-2/Scale" = 1.0;
      "Default/DP-4" = "ASUSTek COMPUTER INC 16\"";
      "Default/DP-4/Active" = true;
      "Default/DP-4/Primary" = false;
      "Default/DP-4/Resolution" = "1920x1200";
      "Default/DP-4/RefreshRate" = 74.94;
      "Default/DP-4/Position/X" = 3840;
      "Default/DP-4/Position/Y" = 960;
      "Default/DP-4/Rotation" = 0;
      "Default/DP-4/Reflection" = "0";
      "Default/DP-4/Scale" = 1.0;
    };

    # XFCE never activates graphical-session.target, so the guard hangs off default.target (the
    # user manager, started at login) and simply retries until the X display is up. No start
    # limit: the retries before X exists must not leave it failed. i3 also starts it at login.
    systemd.user.services.monitor-layout-guard = {
      Unit = {
        Description = "LG (DP-2) + ASUS (DP-4) NVIDIA layout guard";
        StartLimitIntervalSec = 0;
      };
      Service = {
        Environment = [
          "WALLPAPER=${desk.wallpaper}"
          "APPLY_DESK_LAYOUT=${applyLayout}/bin/apply-desk-layout"
          "PATH=${lib.makeBinPath [ pkgs.feh pkgs.procps pkgs.i3 pkgs.xrandr ]}:/usr/bin:/bin"
        ];
        ExecStart = guard;
        Restart = "always";
        RestartSec = "2";
      };
      Install.WantedBy = [ "default.target" ];
    };

    xdg.configFile."autostart/monitors.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Monitor layout guard (systemd)
      Hidden=true
    '';

    home.activation.nvidiaDeskXorg = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      check() {
        if [ -f "$2" ] && ! ${pkgs.diffutils}/bin/cmp -s "$1" "$2"; then
          $DRY_RUN_CMD echo "WARNING: $2 differs from home-manager; run: sudo install -Dm''${3:-644} $1 $2"
        elif [ ! -f "$2" ]; then
          $DRY_RUN_CMD echo "WARNING: missing $2; run: sudo install -Dm''${3:-644} $1 $2"
        fi
      }
      check "${../files/xorg/20-nvidia-desk.conf}" /etc/X11/xorg.conf.d/20-nvidia-desk.conf
      check "${../files/xorg/edid/lg-ultragear.bin}" /etc/X11/edid/lg-ultragear.bin
      check "${../files/xorg/edid/asus-mb16fc.bin}" /etc/X11/edid/asus-mb16fc.bin
      # kernel updates must bring headers, or DKMS can't build the NVIDIA driver (black screen)
      check "${../files/bin/nvidia-kernel-check}" /usr/local/sbin/nvidia-kernel-check 755
      check "${../files/apt/99nvidia-kernel-check}" /etc/apt/apt.conf.d/99nvidia-kernel-check
      check "${../files/grub/nvidia-safe-kernel.cfg}" /etc/default/grub.d/nvidia-safe-kernel.cfg
      check "${../files/systemd/nvidia-kernel-autofix.service}" /etc/systemd/system/nvidia-kernel-autofix.service
      if ! /usr/bin/systemctl is-enabled -q nvidia-kernel-autofix.service 2>/dev/null; then
        $DRY_RUN_CMD echo "WARNING: nvidia-kernel-autofix.service is not enabled; run: sudo systemctl enable nvidia-kernel-autofix.service"
      fi
      if [ "$(/usr/bin/dpkg-query -W -f="\''${Status}" linux-headers-amd64 2>/dev/null)" != "install ok installed" ]; then
        $DRY_RUN_CMD echo "WARNING: linux-headers-amd64 is not installed; run: sudo apt install linux-headers-amd64"
      fi
    '';
  };
}
