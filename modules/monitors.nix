{ lib, config, ... }:

let
  cfg = config.desk.monitors;
in
{
  options.desk.monitors.nvidia = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Apply the LG (DP-2, 4K 240Hz) + ASUS (DP-4, 1.5x ViewPortIn) NVIDIA layout at login.";
  };

  # LG UltraGear on the left (primary, native 4K@240), ASUS MB16FC on the right drawn at
  # 2880x1800 and scaled by the NVIDIA driver so it matches its original size at 144 DPI.
  config = lib.mkIf cfg.nvidia {
    xdg.configFile."autostart/monitors.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Monitor layout
      Exec=sh -c 'nvidia-settings --assign CurrentMetaMode="DP-2: 3840x2160_240 +0+0 {ForceCompositionPipeline=On}, DP-4: 1920x1200_60 +3840+360 {ViewPortIn=2880x1800, ViewPortOut=1920x1200+0+0, ForceCompositionPipeline=On}" && xrandr --output DP-2 --primary'
      X-GNOME-Autostart-enabled=true
    '';
  };
}
