{
  description = "al3rez's Debian desktop: XFCE + i3, macOS-style bar, Ghostty, dunst, picom";

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
  };

  outputs = { nixpkgs, home-manager, nixgl, nix-gl-host, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      mkHome = gpu: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit nixgl gpu; nixglhost = nix-gl-host.packages.${system}.default; };
        modules = [ ./home.nix ];
      };
    in
    {
      # this machine: NVIDIA RTX 5070, LG 4K + ASUS layout
      homeConfigurations.al3rez = mkHome "nvidia";
      # any other box / VM: Mesa GL, no NVIDIA monitor layout
      homeConfigurations.al3rez-vm = mkHome "mesa";
    };
}
