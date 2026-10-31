{ ... }:

{
  xfconf.settings = {
    # 144 DPI (1.5x) on the 4K LG; Inter everywhere; macOS-style icons
    xsettings = {
      "Xft/DPI" = 144;
      "Xft/Antialias" = 1;
      "Xft/HintStyle" = "hintslight";
      "Gdk/WindowScalingFactor" = 1;
      "Gtk/CursorThemeSize" = 36;
      "Gtk/FontName" = "Inter 10";
      "Net/IconThemeName" = "WhiteSur-Mac";
    };

    # xfwm4 is only a fallback now (i3 runs instead); keep it titleless and compositor-free
    xfwm4 = {
      "general/theme" = "NoTitle";
      "general/title_font" = "Inter Bold 10";
      "general/button_layout" = "|";
      "general/use_compositing" = false;
      "general/show_dock_shadow" = false;
      "general/easy_click" = "Alt";
      "general/tile_on_move" = true;
    };

    xfce4-keyboard-shortcuts = {
      # i3 owns Super+E / Super+R
      "commands/custom/<Super>e" = null;
      "commands/custom/<Super>r" = null;
      "commands/custom/<Super>r/startup-notify" = null;
      # Windows-style snapping if you ever go back to xfwm4
      "xfwm4/custom/<Super>Left" = "tile_left_key";
      "xfwm4/custom/<Super>Right" = "tile_right_key";
      "xfwm4/custom/<Super>Up" = "maximize_window_key";
      "xfwm4/custom/<Super>Down" = "hide_window_key";
    };
  };
}
