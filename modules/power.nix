{ pkgs, ... }:

{
  # Like macOS `caffeinate -s`: monitors turn off after 10 idle minutes, the computer never sleeps.
  xfconf.settings.xfce4-power-manager = {
    "xfce4-power-manager/dpms-enabled" = true;
    "xfce4-power-manager/blank-on-ac" = 0;        # no separate blanking step; DPMS turns them off
    "xfce4-power-manager/dpms-on-ac-sleep" = 0;   # no standby step
    "xfce4-power-manager/dpms-on-ac-off" = 10;    # minutes
    "xfce4-power-manager/inactivity-on-ac" = 14;  # 14 = never put the system to sleep
    "xfce4-power-manager/presentation-mode" = false;
    "xfce4-power-manager/lock-screen-suspend-hibernate" = false;
  };

  # XFCE's blank-on-ac=0 does not clear the X server's default 600s screensaver.
  # DPMS remains owned by xfce4-power-manager.
  systemd.user.services.display-blanking = {
    Unit = {
      Description = "Disable X screensaver blanking; keep XFCE DPMS";
      StartLimitIntervalSec = 0;
    };
    Service = {
      Type = "oneshot";
      Environment = [ "DISPLAY=:0" ];
      ExecStart = "${pkgs.xset}/bin/xset s off";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "2";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Hold a logind sleep block for the whole session, so nothing else (a tool, the sleep key,
  # an idle action) can suspend the machine either. Display power is untouched.
  systemd.user.services.caffeine = {
    Unit.Description = "Caffeine: keep the computer awake (display may still turn off)";
    Service = {
      ExecStart = ''/usr/bin/systemd-inhibit --what=sleep --who=caffeine --why="Keep computer awake; display can still sleep" --mode=block /usr/bin/sleep infinity'';
      Restart = "always";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
