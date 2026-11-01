{ pkgs, lib, config, desk, ... }:

let
  # workspace numbers for the xfce4-panel bars (genmon slots are set up in modules/panel.nix)
  wsBar = pkgs.writeScript "i3-ws-bar"
    (builtins.replaceStrings
      [ "@python@" "@i3@" "@i3msg@" "@gdbus@" ]
      [ "${pkgs.python3}/bin/python3" "${pkgs.i3}/bin/i3" "${pkgs.i3}/bin/i3-msg" "${pkgs.glib.bin}/bin/gdbus" ]
      (builtins.readFile ../files/bin/i3-ws-bar));
in
{
  # i3 config with absolute Nix paths, so it never depends on the session's $PATH
  xdg.configFile."i3/config".text =
    builtins.replaceStrings
      [ "@ghostty@" "@feh@" "@wallpaper@" "@dunst@" "@dunstctl@" "@picom@" "@picomconf@" "@i3wsbar@" ]
      [
        "${desk.ghostty}/bin/ghostty"
        "${pkgs.feh}/bin/feh"
        "${desk.wallpaper}"
        "${pkgs.dunst}/bin/dunst"
        "${pkgs.dunst}/bin/dunstctl"
        "${desk.picom}/bin/picom"
        "${config.xdg.configHome}/picom/picom.conf"
        "${wsBar}"
      ]
      (builtins.readFile ../files/i3/config);

  home.activation.reloadI3 = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if ${pkgs.procps}/bin/pgrep -x i3 >/dev/null; then
      run ${pkgs.i3}/bin/i3-msg -q reload || true
    fi
  '';
}
