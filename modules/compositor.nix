{ gpu, ... }:

let
  # GLX for the NVIDIA card; software-GL machines (VMs) need xrender to actually present frames
  backend = if gpu == "nvidia" then "glx" else "xrender";
  # window edge style on app windows (and Clipboard History):
  #   "gloss"    glass glint lit from the top-left (files/picom/gloss.frag)
  #   "ring"     macOS background window: 1px dark outline + 1px light inner rim (edge-ring.frag)
  #   "hairline" macOS key window: 1px light rim, brighter on top (edge-hairline.frag)
  edge = "ring";
  edgeShader = {
    gloss = ../files/picom/gloss.frag;
    ring = ../files/picom/edge-ring.frag;
    hairline = ../files/picom/edge-hairline.frag;
  }.${edge};
  # app window corners (the edge styles above follow either shape):
  #   "square"   flat, no rounding
  #   "rounded"  15px corners (10pt at 1.5x)
  corners = "square";
  radius = { square = "0"; rounded = "15"; }.${corners};
in
{
  # picom: app window corners (`corners` above), unfocused windows dimmed, transparent bar, no
  # shadows, notification slide animation.
  # i3 starts it (see modules/i3.nix): XFCE autostart could race the session and not come up.
  # @gloss@ becomes the edge shader on app windows and @plain@ a pass-through one on fullscreen
  # windows (glx only; xrender has no shaders), so fullscreen never shows an edge.
  # Absolute store paths: picom looks for relative shaders next to the resolved config file,
  # which is a lone file in /nix/store.
  xdg.configFile."picom/picom.conf".text =
    builtins.replaceStrings
      [ ''backend = "glx";'' "@gloss@" "@plain@" "@radius@" ]
      [ ''backend = "${backend}";''
        (if gpu == "nvidia" then ''shader = "${edgeShader}";'' else "")
        (if gpu == "nvidia" then ''shader = "${../files/picom/plain.frag}";'' else "")
        radius ]
      (builtins.readFile ../files/picom/picom.conf);
}
