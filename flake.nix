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
  };

  outputs = { nixpkgs, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      mkHome = gpu: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit nixgl gpu; };
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
