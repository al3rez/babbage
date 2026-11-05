{ gpu, ... }:

let
  # GLX for the NVIDIA card; software-GL machines (VMs) need xrender to actually present frames
  backend = if gpu == "nvidia" then "glx" else "xrender";
  # window edge style on app windows (and Clipboard History):
  #   "gloss"    glass glint lit from the top-left (files/picom/gloss.frag)
  #   "ring"     macOS background window: 1px dark outline + 1px light inner rim (edge-ring.frag)
  #   "hairline" macOS key window: 1px light rim, brighter on top (edge-hairline.frag)
  edge = "hairline";
  edgeShader = {
    gloss = ../files/picom/gloss.frag;
    ring = ../files/picom/edge-ring.frag;
    hairline = ../files/picom/edge-hairline.frag;
  }.${edge};
in
{
  # picom: macOS 15px window corners, unfocused windows dimmed, transparent bar, no shadows,
  # notification slide animation.
  # i3 starts it (see modules/i3.nix): XFCE autostart could race the session and not come up.
  # @gloss@ becomes the edge shader on app windows (glx only; xrender has no shaders).
  # Absolute store path: picom looks for relative shaders next to the resolved config file,
  # which is a lone file in /nix/store.
  xdg.configFile."picom/picom.conf".text =
    builtins.replaceStrings
      [ ''backend = "glx";'' "@gloss@" ]
      [ ''backend = "${backend}";'' (if gpu == "nvidia" then ''shader = "${edgeShader}";'' else "") ]
      (builtins.readFile ../files/picom/picom.conf);
}
