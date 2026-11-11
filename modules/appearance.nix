{ pkgs, lib, ... }:

let
  # light from 07:00, dark from 19:00 (local time)
  lightFrom = "07:00";
  darkFrom = "19:00";

  # Light or dark by the clock. Sets the three places apps read it from:
  #   - GNOME colour scheme: GTK4/libadwaita, Ghostty, Chrome, Electron and the settings portal
  #   - GNOME gtk-theme: apps that read the theme name from dconf
  #   - xsettings Net/ThemeName: GTK3 apps, live
  # These used to be fixed in theme.nix/xfce.nix; they are owned here now so a switch doesn't
  # undo the time of day.
  themeByTime = pkgs.writeShellScript "theme-by-time" ''
    now=$(date +%H%M)
    if [ "$now" -ge ${lib.replaceStrings [ ":" ] [ "" ] lightFrom} ] && [ "$now" -lt ${lib.replaceStrings [ ":" ] [ "" ] darkFrom} ]; then
      scheme=prefer-light gtk=Adwaita
    else
      scheme=prefer-dark gtk=Adwaita-dark
    fi
    /usr/bin/dconf write /org/gnome/desktop/interface/color-scheme "'$scheme'"
    /usr/bin/dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk'"
    /usr/bin/xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "$gtk"
  '';
in
{
  systemd.user.services.theme-by-time = {
    Unit.Description = "Light or dark theme by time of day";
    Service = {
      Type = "oneshot";
      ExecStart = "${themeByTime}";
    };
    Install.WantedBy = [ "default.target" ];   # right at login
  };

  systemd.user.timers.theme-by-time = {
    Unit.Description = "Switch light/dark at ${lightFrom} and ${darkFrom}";
    Timer = {
      OnCalendar = [ "*-*-* ${lightFrom}:00" "*-*-* ${darkFrom}:00" ];
      Persistent = true;   # catch a switch time missed while the machine was off
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # and after every switch, so a fresh install gets the right one straight away
  home.activation.themeByTime = lib.hm.dag.entryAfter [ "dconfSettings" "xfconfSettings" ] ''
    run ${themeByTime} || true
  '';
}
