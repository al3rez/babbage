{ pkgs, lib, desk, ... }:

let
  steam = pkgs.writeShellScriptBin "steam" ''
    exec ${pkgs.flatpak}/bin/flatpak run com.valvesoftware.Steam "$@"
  '';
  # DeepSeek Harness (github.com/deepseek-ai/deepseek-harness), developer preview: runs the
  # pinned npm release; npx caches it in ~/.npm/_npx on first run. `dsh web` serves the Web UI
  # on 127.0.0.1:3080 (open the ?token= URL it prints). It needs Node >= 24.9 and nodejs.org's
  # own build: its native loader disassembles node's internals and rejects nixpkgs' build
  # ("x64 sysv getter is not a recognized this->field accessor"). The binary is used unpatched
  # (code bytes must stay as shipped) with Debian's loader; Debian's own nodejs is too old.
  dshVersion = "0.2.2-rc.1";
  nodeOfficial = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "nodejs-official";
    version = "24.21.0";
    src = pkgs.fetchurl {
      url = "https://nodejs.org/dist/v${version}/node-v${version}-linux-x64.tar.xz";
      hash = "sha256-/Y5Z1aURUQ9qKYr7VI8Yx9KxvkBNi0on2U++SfVsstY=";   # SHASUMS256.txt
    };
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    installPhase = "cp -r . $out";
  };
  dsh = pkgs.writeShellScriptBin "dsh" ''
    export PATH=${nodeOfficial}/bin:$PATH
    exec npx --yes @deepseek-ai/dsh@${dshVersion} "$@"
  '';
in
{
  home.packages = [
    desk.ghostty
    desk.telegram
    desk.slack
    desk.chromium
    desk.tern
    desk.picom
    dsh
    pkgs.i3
    pkgs.dunst
    pkgs.libnotify
    pkgs.feh
    # Steam's Flatpak supplies matching 64/32-bit NVIDIA runtimes on this Debian host.
    pkgs.flatpak

    # Inter is the system UI font; the Nerd Font symbols cover prompt/tab icons
    pkgs.inter
    pkgs.nerd-fonts.symbols-only

    # Nix GUI apps (wrapGAppsHook, nixglhost: Tern, Ghostty, ...) export LD_LIBRARY_PATH and
    # GIO/GDK module paths pointing at Nix's glib. Links they open run Debian's xdg-open ->
    # exo-open -> a host browser with that env, which can die with "GLIBC_2.43 not found".
    # This xdg-open comes first on their PATH and hands over a clean env.
    (lib.hiPrio (pkgs.writeShellScriptBin "xdg-open" ''
      unset LD_LIBRARY_PATH LD_PRELOAD GIO_EXTRA_MODULES GDK_PIXBUF_MODULE_FILE GTK_PATH \
        GST_PLUGIN_SYSTEM_PATH GST_PLUGIN_SYSTEM_PATH_1_0 LIBGL_DRIVERS_PATH GBM_BACKENDS_PATH \
        __EGL_VENDOR_LIBRARY_DIRS __GLX_VENDOR_LIBRARY_NAME
      exec /usr/bin/xdg-open "$@"
    ''))
  ];

  fonts.fontconfig.enable = true;

  home.file.".local/bin/steam".source = "${steam}/bin/steam";

  # Debian's session bus does not discover service files in the Nix profile.
  # Flatpak needs these for sandbox restarts and launching host helpers.
  xdg.dataFile = {
    "dbus-1/services/org.freedesktop.portal.Flatpak.service".source =
      "${pkgs.flatpak}/share/dbus-1/services/org.freedesktop.portal.Flatpak.service";
    "dbus-1/services/org.freedesktop.Flatpak.service".source =
      "${pkgs.flatpak}/share/dbus-1/services/org.freedesktop.Flatpak.service";
    "dbus-1/services/org.flatpak.Authenticator.Oci.service".source =
      "${pkgs.flatpak}/share/dbus-1/services/org.flatpak.Authenticator.Oci.service";
  };
  xdg.configFile = {
    "systemd/user/flatpak-portal.service".source = "${pkgs.flatpak}/lib/systemd/user/flatpak-portal.service";
    "systemd/user/flatpak-session-helper.service".source = "${pkgs.flatpak}/lib/systemd/user/flatpak-session-helper.service";
    "systemd/user/flatpak-oci-authenticator.service".source = "${pkgs.flatpak}/lib/systemd/user/flatpak-oci-authenticator.service";
  };

  home.activation.steam = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists flathub \
      https://flathub.org/repo/flathub.flatpakrepo
    if ! ${pkgs.flatpak}/bin/flatpak info --user com.valvesoftware.Steam >/dev/null 2>&1; then
      run ${pkgs.flatpak}/bin/flatpak install --user --noninteractive -y flathub com.valvesoftware.Steam
    fi
  '';

  # Web links open in Google Chrome. Without a default, xdg-open picks whichever app claims
  # http(s) first, which is ChatGPT's .deb, so links clicked in Slack and other apps went there.
  # Set with xdg-mime (not xdg.mimeApps) so mimeapps.list stays a normal file that apps like
  # Telegram can still add their own link types to. Debian's x-www-browser already points at
  # Chrome: its .deb registers the browser alternative.
  home.activation.webBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -e /usr/share/applications/google-chrome.desktop ]; then
      for t in x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml; do
        run ${pkgs.xdg-utils}/bin/xdg-mime default google-chrome.desktop "$t"
      done
    fi
  '';
  # slack:// links ("Open in the Slack app" in the browser): host browsers may not search
  # ~/.nix-profile/share, so keep the GPU-wrapped Slack entry in the standard user app directory.
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
