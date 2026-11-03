{ gpu, ... }:

let
  # GLX for the NVIDIA card; software-GL machines (VMs) need xrender to actually present frames
  backend = if gpu == "nvidia" then "glx" else "xrender";
in
{
  # picom: macOS 15px window corners, unfocused windows dimmed, transparent bar, no shadows,
  # notification slide animation.
  # i3 starts it (see modules/i3.nix): XFCE autostart could race the session and not come up.
  # @gloss@ becomes the macOS edge shader on app windows (glx only; xrender has no shaders).
  # Absolute store path: picom looks for relative shaders next to the resolved config file,
  # which is a lone file in /nix/store.
  xdg.configFile."picom/picom.conf".text =
    builtins.replaceStrings
      [ ''backend = "glx";'' "@gloss@" ]
      [ ''backend = "${backend}";'' (if gpu == "nvidia" then ''shader = "${../files/picom/gloss.frag}";'' else "") ]
      (builtins.readFile ../files/picom/picom.conf);
}
