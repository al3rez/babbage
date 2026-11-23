{
  description = "Babbage: an opinionated Debian 13 desktop (XFCE + i3, flat menu bar, Ghostty, dunst, picom)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # OpenGL/NVIDIA wrapper so Nix-built GUI apps (Ghostty, Telegram, picom) work on Debian.
    # Kept on its own pinned nixpkgs: its wrappers still use packages unstable has dropped.
    nixgl.url = "github:nix-community/nixGL";
    # NVIDIA: run those apps against the host's own driver libraries instead
    nix-gl-host = {
      url = "github:numtide/nix-gl-host";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Hex voice dictation (modules/hex.nix); same nixpkgs/glibc as the rest, as its docs advise
    hex = {
      url = "github:anomalyco/hex";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { nixpkgs, home-manager, nixgl, nix-gl-host, hex, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      # Any user: whoever runs the switch (needs --impure; bootstrap.sh passes it). The ISO's
      # installer lets you pick the name, as Omarchy's does.
      user = let u = builtins.getEnv "USER"; in
        if u == "" then throw "Babbage reads your username from $USER: add --impure to home-manager switch" else u;
      mkHome = gpu: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit nixgl gpu hex user; nixglhost = nix-gl-host.packages.${system}.default; };
        modules = [ ./home.nix ];
      };
    in
    {
      # this machine: NVIDIA RTX 5070, LG 4K + ASUS layout
      homeConfigurations.al3rez = mkHome "nvidia";
      # any other box / VM (and the ISO): Mesa GL, no NVIDIA monitor layout
      homeConfigurations.generic = mkHome "mesa";
    };
}
