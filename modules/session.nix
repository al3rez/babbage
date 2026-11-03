{ pkgs, ... }:

{
  # Bangkok (ICT, UTC+7). Debian defaults to US/Eastern on this install; session TZ fixes
  # panel clock, shells, and GUI apps without waiting on timedatectl.
  home.sessionVariables = {
    TZ = "Asia/Bangkok";
    # same cursor for apps that read the env instead of XSETTINGS (Qt, Electron); keep in
    # sync with Gtk/CursorThemeName/Size in modules/xfce.nix
    XCURSOR_THEME = "mate-black";
    XCURSOR_SIZE = "32";
  };
  # apps that ask for the "default" cursor theme (no setting read at all) get the same one.
  # XCURSOR_PATH is ~/.nix-profile/share/icons:/usr/share/icons, so this beats Debian's
  # /usr/share/icons/default (the light mate theme)
  home.packages = [
    (pkgs.writeTextDir "share/icons/default/index.theme" ''
      [Icon Theme]
      Inherits=mate-black
    '')
  ];

  # Debian's Xsession sources ~/.xsessionrc, so the XFCE session (and i3, the panel,
  # the app menu) see Nix-installed binaries, apps and session variables.
  home.file.".xsessionrc".text = ''
    if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
      . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    fi
    export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
    export XDG_DATA_DIRS="$HOME/.nix-profile/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  '';

  # XFCE session runs i3 instead of xfwm4, and no xfdesktop (feh sets the wallpaper)
  xfconf.settings.xfce4-session = {
    "general/SaveOnExit" = false;
    "sessions/Failsafe/Client0_Command" = [ "${pkgs.i3}/bin/i3" ];
    "sessions/Failsafe/Count" = 4;
  };
}
