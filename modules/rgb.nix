{ pkgs, lib, gpu, ... }:

let
  # RGB off on every login: the two ENE DRAM sticks and the ASRock B850M board's Polychrome
  # controller (its RGB header + 3 addressable headers). RAM lighting falls back to its rainbow
  # default when power is cut, so it's set again each time. Devices are picked by name (their
  # numbers can shift); the Logitech G304 is left alone (no RGB, and OpenRGB would write to its
  # onboard memory). Needs OpenRGB's udev rules in /etc/udev/rules.d (bootstrap.sh installs them).
  rgbOff = pkgs.writeShellScript "rgb-off" ''
    openrgb=${pkgs.openrgb}/bin/openrgb
    args=
    for d in $($openrgb --noautoconnect --list-devices | ${pkgs.gnugrep}/bin/grep -E '^[0-9]+: (ENE DRAM|ASRock)' | ${pkgs.coreutils}/bin/cut -d: -f1); do
      args="$args -d $d -m off"
    done
    [ -n "$args" ] || { echo "rgb-off: no RGB devices found (udev rules missing?)"; exit 1; }
    exec $openrgb --noautoconnect $args
  '';
in
# this machine's hardware only (the NVIDIA desk profile); elsewhere there's nothing to turn off
lib.mkIf (gpu == "nvidia") {
  home.packages = [ pkgs.openrgb ];

  systemd.user.services.rgb-off = {
    Unit.Description = "Turn off RAM and motherboard RGB lighting (OpenRGB)";
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${rgbOff}";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
