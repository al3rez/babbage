{ config, pkgs, nixgl, gpu, ... }:

let
  gl = config.lib.nixGL.wrap;
in
{
  imports = [
    ./modules/packages.nix
    ./modules/session.nix
    ./modules/xfce.nix
    ./modules/panel.nix
    ./modules/i3.nix
    ./modules/compositor.nix
    ./modules/notifications.nix
    ./modules/ghostty.nix
    ./modules/theme.nix
    ./modules/shell.nix
    ./modules/monitors.nix
  ];

  home.username = "al3rez";
  home.homeDirectory = "/home/al3rez";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  # Debian (not NixOS): set up XDG/session plumbing for Nix-installed apps, plus the GL
  # wrapper for Nix GUI apps (the NVIDIA one reads the driver version at switch time,
  # hence `--impure`)
  targets.genericLinux = {
    enable = true;
    nixGL = {
      packages = nixgl.packages;
      defaultWrapper = gpu;
      installScripts = [ gpu ];
    };
  };
  xdg.enable = true;

  desk.monitors.nvidia = gpu == "nvidia";

  # Shared by the modules: GL-wrapped apps and the wallpaper
  _module.args.desk = {
    ghostty = gl pkgs.ghostty;
    telegram = gl pkgs.telegram-desktop;
    picom = gl pkgs.picom;
    wallpaper = pkgs.fetchurl {
      name = "wallhaven-gp7mq3.jpg";
      url = "https://w.wallhaven.cc/full/gp/wallhaven-gp7mq3.jpg";
      hash = "sha256-4xcsIF6BYIi+y+iRnARVfKwt56YWcOUqiQZ61cMIzdI=";
    };
  };
}
