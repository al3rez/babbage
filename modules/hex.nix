{ hex, desk, ... }:

# Hex (anoma.ly/hex): local voice dictation. Hold Alt+Space, speak, release; the text is pasted
# where the cursor is (Ctrl+Alt+V pastes the last one again). Built from the official flake
# (github:anomalyco/hex) with its Home Manager module; Nix owns updates (`nix flake update hex`).
{
  imports = [ hex.homeManagerModules.hex ];

  programs.hex = {
    enable = true;
    package = desk.hex;   # GPU-wrapped in home.nix: Vulkan runs on the host's driver
    # XFCE never starts graphical-session.target, so the unit is started from i3 instead
    # (files/i3/config), like clipboard-history and menubar-popovers
    autostart = false;
    installModel = true;   # the hex-model user service downloads the default model once
    # open the mic only while dictating, so the bar's mic indicator means "recording now" (as on
    # macOS) instead of staying lit while Hex idles
    settings.release_microphone_while_idle = true;
  };
}
