{ gpu, ... }:

let
  # GLX for the NVIDIA card; software-GL machines (VMs) need xrender to actually present frames
  backend = if gpu == "nvidia" then "glx" else "xrender";
in
{
  # picom: macOS 15px window corners, unfocused windows dimmed, transparent bar, no shadows,
  # notification slide animation.
  # i3 starts it (see modules/i3.nix): XFCE autostart could race the session and not come up.
  xdg.configFile."picom/picom.conf".text =
    builtins.replaceStrings [ ''backend = "glx";'' ] [ ''backend = "${backend}";'' ]
      (builtins.readFile ../files/picom/picom.conf);
}
