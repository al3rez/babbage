{ pkgs, lib, desk, ... }:

{
  home.packages = [
    desk.ghostty
    desk.telegram
    desk.slack
    desk.chromium
    desk.tern
    desk.picom
    pkgs.i3
    pkgs.dunst
    pkgs.libnotify
    pkgs.feh

    # Inter is the system UI font; the Nerd Font symbols cover prompt/tab icons
    pkgs.inter
    pkgs.nerd-fonts.symbols-only

    # Nix GUI apps (wrapGAppsHook, nixglhost: Tern, Ghostty, ...) export LD_LIBRARY_PATH and
    # GIO/GDK module paths pointing at Nix's glib. Links they open run Debian's xdg-open ->
    # exo-open -> firefox-esr with that env, which die at once ("GLIBC_2.43 not found"), so
    # clicking a link did nothing. This xdg-open comes first on their PATH and hands over a
    # clean env.
    (lib.hiPrio (pkgs.writeShellScriptBin "xdg-open" ''
      unset LD_LIBRARY_PATH LD_PRELOAD GIO_EXTRA_MODULES GDK_PIXBUF_MODULE_FILE GTK_PATH \
        GST_PLUGIN_SYSTEM_PATH GST_PLUGIN_SYSTEM_PATH_1_0 LIBGL_DRIVERS_PATH GBM_BACKENDS_PATH \
        __EGL_VENDOR_LIBRARY_DIRS __GLX_VENDOR_LIBRARY_NAME
      exec /usr/bin/xdg-open "$@"
    ''))
  ];

  fonts.fontconfig.enable = true;

  # Web links open in Google Chrome. Without a default, xdg-open picks whichever app claims
  # http(s) first, which is ChatGPT's .deb, so links clicked in Slack and other apps went there.
  # Set with xdg-mime (not xdg.mimeApps) so mimeapps.list stays a normal file that apps like
  # Telegram can still add their own link types to. Debian's x-www-browser already points at
  # Chrome: its .deb registers that alternative at a higher priority than Firefox ESR.
  home.activation.webBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -e /usr/share/applications/google-chrome.desktop ]; then
      for t in x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml; do
        run ${pkgs.xdg-utils}/bin/xdg-mime default google-chrome.desktop "$t"
      done
    fi
  '';
  # slack:// links ("Open in the Slack app" in the browser): Firefox's XDG_DATA_DIRS doesn't include
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
  # (asks with a dialog when none is set); /usr/share/xfce4/helpers/google-chrome.desktop
  xdg.configFile."xfce4/helpers.rc".text = ''
    WebBrowser=google-chrome
  '';
}
