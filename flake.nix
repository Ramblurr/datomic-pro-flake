{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    clj-nix.url = "github:jlesquembre/clj-nix";
    snowfall-drift = {
      url = "github:snowfallorg/drift";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      clj-nix,
      snowfall-drift
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            clj-nix.overlays.default
            snowfall-drift.overlays.default
            self.overlays."${system}"
          ];
        };
      in
      {
        overlays = final: prev: {
          datomic-pro = pkgs.callPackage ./pkgs/datomic-pro.nix { };
          datomic-pro-peer = pkgs.callPackage ./pkgs/datomic-pro-peer.nix { };
          datomic-pro-container = pkgs.callPackage ./pkgs/datomic-pro-container-image.nix {
            imageTag = final.datomic-pro.version;
          };
          datomic-pro-container-unstable = pkgs.callPackage ./pkgs/datomic-pro-container-image.nix {
            imageTag = "unstable";
          };
          datomic-generate-properties = pkgs.callPackage ./pkgs/datomic-generate-properties.nix { };
        };
        packages = {
          default = self.packages.${system}.datomic-pro;
          datomic-pro = pkgs.datomic-pro;
          datomic-pro-peer = pkgs.datomic-pro-peer;
          datomic-pro-container = pkgs.datomic-pro-container;
          datomic-pro-container-unstable = pkgs.datomic-pro-container-unstable;
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
            snowfall-drift.packages.${system}.drift
            pkgs.skopeo
            pkgs.babashka
            pkgs.dive
            pkgs.gnumake
          ];
        };
      }
    );
}
