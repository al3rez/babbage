{ pkgs, lib, desk, ... }:

{
  home.packages = [
    desk.ghostty
    desk.telegram
    desk.slack
    desk.chromium
    desk.picom
    pkgs.i3
    pkgs.dunst
    pkgs.libnotify
    pkgs.feh

    # Inter is the system UI font; the Nerd Font symbols cover prompt/tab icons
    pkgs.inter
    pkgs.nerd-fonts.symbols-only
  ];

  fonts.fontconfig.enable = true;

  # Web links open in Firefox. Without a default, xdg-open picks whichever app claims http(s)
  # first, which is ChatGPT's .deb, so links clicked in Slack and other apps went there.
  # Set with xdg-mime (not xdg.mimeApps) so mimeapps.list stays a normal file that apps like
  # Telegram can still add their own link types to.
  home.activation.webBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -e /usr/share/applications/firefox-esr.desktop ]; then
      for t in x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml; do
        run ${pkgs.xdg-utils}/bin/xdg-mime default firefox-esr.desktop "$t"
      done
    fi
  '';
  # slack:// links ("Open in the Slack app" in Firefox): Firefox's XDG_DATA_DIRS doesn't include
  # ~/.nix-profile/share, so it can't see Slack's own entry there; this one is always found
  # (same name, so it also replaces that entry) and runs the GPU-wrapped Slack
  xdg.dataFile."applications/slack.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Slack
    Comment=Slack Desktop
    Exec=${desk.slack}/bin/slack -s %U
    Icon=slack-mac
    StartupWMClass=Slack
    Terminal=false
    Categories=Network;InstantMessaging;
    MimeType=x-scheme-handler/slack;
  '';

  # on XFCE, xdg-open hands web links to exo-open, which uses XFCE's own preferred browser
  # (asks with a dialog when none is set)
  xdg.configFile."xfce4/helpers.rc".text = ''
    WebBrowser=firefox
  '';
}
