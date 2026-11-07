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
    # keep the mic open between dictations (Hex's default): reopening the OBSBOT webcam mic on
    # every key press loses the start of short dictations ("discarded ... without detected
    # speech"). The tray's mic follows Hex's own recording state instead (files/bin/menubar-popovers)
    settings.release_microphone_while_idle = false;
  };
}
