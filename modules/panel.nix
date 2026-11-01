{ pkgs, lib, config, desk, ... }:

let
  # NVIDIA layout: one bar per monitor, each listing only its own workspaces.
  # Elsewhere: a single bar listing every workspace ("_all" is i3-ws-bar's wildcard output).
  dual = config.desk.monitors.nvidia;
  primaryOutput = if dual then "DP-2" else "_all";

  # nine genmon slots (workspaces 1-9) for one output, plugin ids first..first+8
  wsIds = first: lib.genList (i: first + i) 9;
  wsPlugins = first: lib.listToAttrs (map (id: lib.nameValuePair "plugins/plugin-${toString id}" "genmon") (wsIds first));
  wsRcFiles = first: output: lib.genList (i: {
    name = "genmon-${toString (first + i)}.rc";
    path = pkgs.writeText "genmon-${toString (first + i)}.rc" ''
      Command=cat ${config.xdg.cacheHome}/i3-ws-bar/${output}/${toString (i + 1)}.genmon
      UseLabel=0
      Text=
      UpdatePeriod=30000
      Font=Inter 10

    '';
  }) 9;
  genmonSlots = pkgs.linkFarm "genmon-slots"
    (wsRcFiles 35 primaryOutput ++ lib.optionals dual (wsRcFiles 46 "DP-4"));

  separator = id: expand: {
    "plugins/plugin-${toString id}" = "separator";
    "plugins/plugin-${toString id}/style" = 0;
    "plugins/plugin-${toString id}/expand" = expand;
  };
  launcher = id: item: {
    "plugins/plugin-${toString id}" = "launcher";
    "plugins/plugin-${toString id}/items" = [ item ];
  };
  clock = id: {
    "plugins/plugin-${toString id}" = "clock";
    "plugins/plugin-${toString id}/mode" = 2;
    "plugins/plugin-${toString id}/digital-layout" = 3;
    "plugins/plugin-${toString id}/digital-time-font" = "Inter 10";
    "plugins/plugin-${toString id}/digital-time-format" = "%a %b %-d  %-I:%M %p";
  };
  panelLook = n: {
    "panels/panel-${toString n}/position" = "p=9;x=0;y=0";
    "panels/panel-${toString n}/position-locked" = true;
    "panels/panel-${toString n}/length" = 100;
    "panels/panel-${toString n}/size" = 36;
    "panels/panel-${toString n}/icon-size" = 30;
    "panels/panel-${toString n}/background-style" = 1;
    "panels/panel-${toString n}/background-rgba" = [ 0.0 0.0 0.0 0.0 ];
    "panels/panel-${toString n}/enter-opacity" = 100;
    "panels/panel-${toString n}/leave-opacity" = 100;
  };

  ghosttyDesktop = ''
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=Ghostty
    Comment=A terminal emulator
    Exec=${desk.ghostty}/bin/ghostty
    Icon=com.mitchellh.ghostty
    StartupWMClass=com.mitchellh.ghostty
    Terminal=false
  '';
in
{
  # Top menu bar: workspace numbers, Ghostty + Grok Bot + Firefox on the left,
  # tray/volume/search/control centre/clock on the right. Its ends line up with i3's
  # window gaps (end spacers + gtk.css padding).
  xfconf.settings.xfce4-panel = {
    "panels" = if dual then [ 1 2 ] else [ 1 ];
    "panels/dark-mode" = true;
    "panels/panel-1/plugin-ids" = [ 32 ] ++ wsIds 35 ++ [ 44 27 34 29 3 6 21 25 26 8 33 ];

    # status area (tray and volume keys exist only once, on the primary bar)
    "plugins/plugin-6" = "systray";
    "plugins/plugin-6/icon-size" = 30;
    "plugins/plugin-6/square-icons" = true;
    "plugins/plugin-21" = "pulseaudio";
    "plugins/plugin-21/enable-keyboard-shortcuts" = true;

    # app menu still reachable with Super+Space (not on the bar)
    "plugins/plugin-19" = "whiskermenu";
    "plugins/plugin-19/button-icon" = "menu-grid-symbolic";
    "plugins/plugin-19/show-button-title" = false;
  }
  // panelLook 1
  // wsPlugins 35
  // separator 32 false // separator 33 false   # left/right end spacers
  // separator 44 false                          # gap between workspaces and apps
  // launcher 27 "ghostty.desktop" // launcher 34 "grok-bot.desktop" // launcher 29 "firefox.desktop"
  // separator 3 true                            # middle stretch
  // launcher 25 "spotlight.desktop" // launcher 26 "control-center.desktop"
  // clock 8   # "Fri Oct 30  10:45 PM"
  // lib.optionalAttrs dual ({
    # LG on the left, ASUS on the right: same bar on each, minus the tray
    "panels/panel-1/output-name" = "DP-2";
    "panels/panel-2/output-name" = "DP-4";
    "panels/panel-2/plugin-ids" = [ 45 ] ++ wsIds 46 ++ [ 55 56 57 58 59 60 61 62 63 64 ];
    "plugins/plugin-60" = "pulseaudio";
    "plugins/plugin-60/enable-keyboard-shortcuts" = false;  # volume keys are handled once, by plugin-21
  }
  // panelLook 2
  // wsPlugins 46
  // separator 45 false // separator 64 false
  // separator 55 false
  // launcher 56 "ghostty.desktop" // launcher 57 "grok-bot.desktop" // launcher 58 "firefox.desktop"
  // separator 59 true
  // launcher 61 "spotlight.desktop" // launcher 62 "control-center.desktop"
  // clock 63);

  xdg.configFile = {
    "xfce4/panel/launcher-27/ghostty.desktop".text = ghosttyDesktop;
    "xfce4/panel/launcher-34/grok-bot.desktop".source = ../files/panel/grok-bot.desktop;
    "xfce4/panel/launcher-29/firefox.desktop".source = ../files/panel/launcher-29/firefox.desktop;
    "xfce4/panel/launcher-25/spotlight.desktop".source = ../files/panel/launcher-25/spotlight.desktop;
    "xfce4/panel/launcher-26/control-center.desktop".source = ../files/panel/launcher-26/control-center.desktop;
  } // lib.optionalAttrs dual {
    "xfce4/panel/launcher-56/ghostty.desktop".text = ghosttyDesktop;
    "xfce4/panel/launcher-57/grok-bot.desktop".source = ../files/panel/grok-bot.desktop;
    "xfce4/panel/launcher-58/firefox.desktop".source = ../files/panel/launcher-29/firefox.desktop;
    "xfce4/panel/launcher-61/spotlight.desktop".source = ../files/panel/launcher-25/spotlight.desktop;
    "xfce4/panel/launcher-62/control-center.desktop".source = ../files/panel/launcher-26/control-center.desktop;
  };

  # Pick up panel changes in a running session. genmon keeps its settings in memory and
  # writes them back to genmon-N.rc when the panel exits, so the workspace slot files are
  # real (writable) files, only replaced while the panel is stopped.
  home.activation.reloadPanel = lib.hm.dag.entryAfter [ "xfconfSettings" "linkGeneration" ] ''
    panelDir="${config.xdg.configHome}/xfce4/panel"
    stale=
    for f in ${genmonSlots}/*.rc; do
      ${pkgs.diffutils}/bin/cmp -s "$f" "$panelDir/''${f##*/}" || stale=1
    done
    running=
    if ${pkgs.procps}/bin/pgrep -x xfce4-panel >/dev/null; then running=1; fi

    if [ -n "$stale" ]; then
      if [ -n "$running" ]; then
        run /usr/bin/xfce4-panel -q || true
        for _ in $(seq 50); do ${pkgs.procps}/bin/pgrep -x xfce4-panel >/dev/null || break; sleep 0.1; done
      fi
      run mkdir -p "$panelDir"
      for f in ${genmonSlots}/*.rc; do
        run install -m 644 "$f" "$panelDir/''${f##*/}"
      done
      if [ -n "$running" ]; then
        if ${pkgs.procps}/bin/pgrep -x i3 >/dev/null; then
          run ${pkgs.i3}/bin/i3-msg -q exec --no-startup-id /usr/bin/xfce4-panel || true
        else
          run setsid -f /usr/bin/xfce4-panel >/dev/null 2>&1 || true
        fi
      fi
    elif [ -n "$running" ]; then
      run /usr/bin/xfce4-panel -r || true
    fi
  '';
}
