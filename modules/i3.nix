{ pkgs, lib, config, desk, ... }:

let
  # workspace numbers for the xfce4-panel bars (genmon slots are set up in modules/panel.nix)
  applyLayout =
    if config.desk.monitors.nvidia then
      pkgs.writeShellScriptBin "apply-desk-layout" (
        lib.removePrefix "#!/usr/bin/env bash\n" (builtins.readFile ../files/bin/apply-desk-layout)
      )
    else
      "${pkgs.coreutils}/bin/true";
  wsBar = pkgs.writeScript "i3-ws-bar"
    (builtins.replaceStrings
      [ "@python@" "@i3@" "@i3msg@" "@gdbus@" ]
      [ "${pkgs.python3}/bin/python3" "${pkgs.i3}/bin/i3" "${pkgs.i3}/bin/i3-msg" "${pkgs.glib.bin}/bin/gdbus" ]
      (builtins.readFile ../files/bin/i3-ws-bar));
  # Raycast-style launcher (Super+Space): rofi in dmenu mode with files/rofi/launcher.rasi
  launcher = pkgs.writeScript "launcher"
    (builtins.replaceStrings
      [ "@python@" "@rofi@" "@theme@" "@gtklaunch@" ]
      [ "${pkgs.python3}/bin/python3" "${pkgs.rofi}/bin/rofi" "${../files/rofi/launcher.rasi}" "${pkgs.gtk3}/bin/gtk-launch" ]
      (builtins.readFile ../files/bin/launcher));
  # macOS ⌘⇧4 (Ctrl+Shift+4): drag a region, saved to ~/Pictures/Screenshots and copied to
  # the clipboard. xfce4-screenshooter can't do both (with -c it skips -s), so xclip copies the
  # saved file. Esc cancels: no file, nothing copied.
  screenshotRegion = pkgs.writeShellScript "screenshot-region" ''
    dir="$HOME/Pictures/Screenshots"
    mkdir -p "$dir"
    f="$dir/Screenshot $(date '+%Y-%m-%d at %H.%M.%S').png"
    /usr/bin/xfce4-screenshooter -r -s "$f"
    [ -f "$f" ] && exec ${pkgs.xclip}/bin/xclip -selection clipboard -t image/png -i "$f"
  '';
  # Clipboard History (files/bin/clipboard-history): the systemd service records copies;
  # Super+Shift+V runs the same script, which asks the running copy to show its window (the
  # launcher's look plus a preview). Nix GTK + typelibs, as for the menu bar popovers.
  clipboardHistory = pkgs.writeShellScript "clipboard-history" ''
    export GI_TYPELIB_PATH=${lib.makeSearchPathOutput "out" "lib/girepository-1.0"
      (with pkgs; [ gtk3 gdk-pixbuf pango atk harfbuzz glib gobject-introspection ])}
    unset GTK_MODULES GTK_PATH   # Debian's GTK modules don't load into Nix's GTK
    export GDK_PIXBUF_MODULE_FILE=${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache   # SVG icons
    export LC_ALL=C.UTF-8        # Nix's glibc can't load Debian's locales
    export I3MSG=${pkgs.i3}/bin/i3-msg LAUNCHER_THEME=${../files/rofi/launcher.rasi}   # same look as Super+Space
    exec ${pkgs.python3.withPackages (p: [ p.pygobject3 p.xlib ])}/bin/python3 ${../files/bin/clipboard-history} "$@"
  '';
in
{
  # i3 config with absolute Nix paths, so it never depends on the session's $PATH
  xdg.configFile."i3/config".text =
    builtins.replaceStrings
      [ "@ghostty@" "@feh@" "@wallpaper@" "@dunst@" "@dunstctl@" "@picom@" "@picomconf@" "@i3wsbar@" "@launcher@" "@applylayout@" "@screenshotregion@" "@clipboard@" ]
      [
        "${desk.ghostty}/bin/ghostty"
        "${pkgs.feh}/bin/feh"
        "${desk.wallpaper}"
        "${pkgs.dunst}/bin/dunst"
        "${pkgs.dunst}/bin/dunstctl"
        "${desk.picom}/bin/picom"
        "${config.xdg.configHome}/picom/picom.conf"
        "${wsBar}"
        "${launcher}"
        "${applyLayout}/bin/apply-desk-layout"
        "${screenshotRegion}"
        "${clipboardHistory}"
      ]
      (builtins.readFile ../files/i3/config);

  # the same launcher as `launcher` in the profile: the menu bar's search icon opens it too
  # (modules/panel.nix, launcher-25/61)
  home.packages = [ (pkgs.runCommand "launcher" { } "mkdir -p $out/bin && ln -s ${launcher} $out/bin/launcher") ];

  # the clipboard recorder. Like the monitor guard it hangs off default.target (XFCE never starts
  # graphical-session.target) and retries until X is up; i3 also starts it at login.
  systemd.user.services.clipboard-history = {
    Unit = {
      Description = "Raycast-style clipboard history (records copies; Super+Shift+V)";
      StartLimitIntervalSec = 0;
    };
    Service = {
      Environment = [
        "DISPLAY=:0"
        "XDG_DATA_DIRS=%h/.nix-profile/share:/usr/local/share:/usr/share"   # app names + icons
      ];
      ExecStart = "${clipboardHistory} --daemon";
      Restart = "always";
      RestartSec = "2";
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.activation.reloadI3 = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if ${pkgs.procps}/bin/pgrep -x i3 >/dev/null; then
      run ${pkgs.i3}/bin/i3-msg -q reload || true
    fi
  '';
}
