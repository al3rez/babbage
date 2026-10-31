{ pkgs, lib, config, desk, ... }:

{
  # i3 config with absolute Nix paths, so it never depends on the session's $PATH
  xdg.configFile."i3/config".text =
    builtins.replaceStrings
      [ "@ghostty@" "@feh@" "@wallpaper@" "@dunst@" "@dunstctl@" "@picom@" "@picomconf@" ]
      [
        "${desk.ghostty}/bin/ghostty"
        "${pkgs.feh}/bin/feh"
        "${desk.wallpaper}"
        "${pkgs.dunst}/bin/dunst"
        "${pkgs.dunst}/bin/dunstctl"
        "${desk.picom}/bin/picom"
        "${config.xdg.configHome}/picom/picom.conf"
      ]
      (builtins.readFile ../files/i3/config);

  home.activation.reloadI3 = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if ${pkgs.procps}/bin/pgrep -x i3 >/dev/null; then
      run ${pkgs.i3}/bin/i3-msg -q reload || true
    fi
  '';
}
