{
  description = " Nix flake that ports UGreen LED controller & kernel module";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" ];
    in
    {
      nixosModules = {
        default = self.nixosModules.ugreen-led;
        ugreen-led = ./modules;
      };

      overlays.default = final: prev: {
        ugreen-leds = prev.callPackage ./pkgs/ugreen-leds { };
      };

      # 'nix build .#package' - inputs.ugreen-led.packages.${system}.<package>
      packages = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        self.overlays.default pkgs pkgs
      );
    };
}
