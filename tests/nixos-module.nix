{
  self,
  system,
  pkgs,
  nixpkgs,
}:

with import (nixpkgs + "/nixos/lib/testing-python.nix") { inherit system pkgs; };
with pkgs.lib;

makeTest {
  name = "datomic-pro module test";
  nodes = {
    client =
      { ... }:
      {
        nixpkgs.overlays = [ self.overlays."${system}" ];
        virtualisation.memorySize = 2048;
        imports = [
          self.nixosModules.${system}.datomic-pro
          self.nixosModules.${system}.datomic-console
        ];
        environment.etc."datomic-pro/do-not-do-this.properties" = {
          text = ''
            storage-admin-password=do-not-do-it-this-way-in-prod
            storage-datomic-password=do-not-do-it-this-way-in-prod
          '';
          mode = "0600";
        };
        services.datomic-pro = {
          enable = true;
          secretsFile = "/etc/datomic-pro/do-not-do-this.properties";
          settings = {
            enable = true;
            host = "localhost";
            port = 4334;
            memory-index-max = "256m";
            memory-index-threshold = "32m";
            object-cache-max = "128m";
            protocol = "dev";
            storage-access = "remote";
          };
        };

        environment.etc."datomic-console/do-not-do-this" = {
          text = "datomic:dev://localhost:4334/?password=do-not-do-it-this-way-in-prod";
          mode = "0600";
        };
        services.datomic-console = {
          enable = true;
          alias = "dev";
          port = 8080;
          dbUriFile = "/etc/datomic-console/do-not-do-this";
        };
      };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("datomic-pro.service")
    machine.wait_for_open_port(4334)

    machine.wait_for_unit("datomic-console.service")
    machine.wait_for_open_port(8080)
    machine.succeed("curl --fail http://localhost:8080/browse")
  '';
}
