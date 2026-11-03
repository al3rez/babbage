{ config, lib, pkgs, nixgl, nixglhost, gpu, ... }:

let
  # NVIDIA: run GL apps against the host's own driver libraries (nix-gl-host), so they always
  # match whatever driver apt installed. nixGL instead downloads the driver .run from
  # download.nvidia.com/XFree86/..., which 404s for CUDA-repo drivers (615.71.10 only exists
  # under /tesla/), and would need a flake update after every driver upgrade.
  hostGL = pkg: pkgs.symlinkJoin {
    name = "${pkg.name}-hostgl";
    paths = [ pkg ];
    postBuild = ''
      for b in $out/bin/*; do
        t=$(readlink -f "$b"); rm "$b"
        printf '#!%s\nexec %s %s "$@"\n' ${pkgs.runtimeShell} ${nixglhost}/bin/nixglhost "$t" > "$b"
        chmod +x "$b"
      done
    '';
  };
  gl = if gpu == "nvidia" then hostGL else config.lib.nixGL.wrap;
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
    ./modules/power.nix
    ./modules/network.nix
  ];

  home.username = "al3rez";
  home.homeDirectory = "/home/al3rez";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  # Debian (not NixOS): set up XDG/session plumbing for Nix-installed apps, plus nixGL's
  # Mesa wrapper for Nix GUI apps on non-NVIDIA machines
  targets.genericLinux = {
    enable = true;
    nixGL = lib.mkIf (gpu != "nvidia") {
      packages = nixgl.packages;
      defaultWrapper = "mesa";
      installScripts = [ "mesa" ];
    };
    # GL apps get their drivers from the wrappers above (nix-gl-host on NVIDIA, nixGL elsewhere).
    # Home Manager's own GPU module would need the NVIDIA .run from download.nvidia.com (404 for
    # this CUDA-repo driver) plus a root setup step, and warned on every switch.
    gpu.enable = false;
  };
  xdg.enable = true;

  desk.monitors.nvidia = gpu == "nvidia";

  # Shared by the modules: GL-wrapped apps and the wallpaper
  _module.args.desk = {
    ghostty = gl pkgs.ghostty;
    telegram = gl pkgs.telegram-desktop;
    picom = gl pkgs.picom;
    slack = gl pkgs.slack;
    chromium = gl pkgs.chromium;   # runs web apps (WhatsApp) in their own windows, like Omarchy
    tern = gl (pkgs.callPackage ./files/pkgs/tern.nix { });   # Stencil's prebuilt tarball
    wallpaper = pkgs.fetchurl {
      name = "wallhaven-gp7mq3.jpg";
      url = "https://w.wallhaven.cc/full/gp/wallhaven-gp7mq3.jpg";
      hash = "sha256-4xcsIF6BYIi+y+iRnARVfKwt56YWcOUqiQZ61cMIzdI=";
    };
  };
}
