{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays."${system}" ];
        };

        jdk-minimal = pkgs.jdk21_headless;
      in
      {
        overlays = final: prev: {
          datomic-pro = pkgs.callPackage ./pkgs/datomic-pro.nix { };
          datomic-pro-container = pkgs.callPackage ./pkgs/datomic-pro-container-image.nix { };
          datomic-generate-properties = pkgs.callPackage ./pkgs/datomic-generate-properties.nix { };
        };
        packages = {
          default = self.packages.${system}.datomic-pro;
          datomic-pro = pkgs.datomic-pro;
          datomic-pro-container = pkgs.datomic-pro-container;
          datomic-generate-properties = pkgs.datomic-generate-properties;
        };
        nixosModules = {
          datomic-pro = import ./nixos-modules/datomic-pro.nix;
          datomic-console = import ./nixos-modules/datomic-console.nix;
        };
        checks = {
          # A test of the NixOS module that runs in a VM
          moduleTest = import ./tests/nixos-module.nix {
            inherit
              system
              pkgs
              nixpkgs
              self
              ;
          };

          # A test of the container image that runs in a VM
          containerImageTest = import ./tests/container-image.nix {
            inherit
              system
              pkgs
              nixpkgs
              self
              ;
          };
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.skopeo
            pkgs.babashka
            pkgs.gnumake
          ];
        };
      }
    );
}
