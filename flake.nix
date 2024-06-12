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
      in
      {
        overlays = final: prev: { datomic-pro = pkgs.callPackage ./pkgs/datomic-pro.nix { }; };
        packages = {
          default = self.packages.${system}.datomic-pro;
          datomic-pro = pkgs.datomic-pro;
        };
        nixosModules = {
          datomic-pro = import ./nixos-modules/datomic-pro.nix;
        };
        checks = {
          # A VM test of the NixOS module.
          vmTest =
            with import (nixpkgs + "/nixos/lib/testing-python.nix") { inherit system; };

            makeTest {
              name = "datomic-pro module test";
              nodes = {
                client =
                  { ... }:
                  {
                    nixpkgs.overlays = [ self.overlays."${system}" ];
                    virtualisation.memorySize = 2048;
                    imports = [ self.nixosModules.${system}.datomic-pro ];
                    services.datomic-pro.enable = true;
                  };
              };

              testScript = ''
                start_all()
                machine.sleep(5)
                machine.wait_for_unit("datomic-pro.service")
                machine.wait_for_open_port(4334)
              '';
            };
        };
      }
    );
}
