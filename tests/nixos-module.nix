{
  self,
  system,
  pkgs,
  nixpkgs,
}:

let
  inherit
    (import (nixpkgs + "/nixos/lib/testing-python.nix") {
      inherit system pkgs;
    })
    makeTest
    ;
in
makeTest {
  name = "datomic-pro module test";
  nodes = {
    client =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        package = config.services.datomic-pro.package;
        version = config.services.datomic-pro.package.version;
      in
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
            storage-datomic-password=do-not-do-it-this-way-in-prod-peer
          '';
          mode = "0600";
        };
        services.datomic-pro = {
          enable = true;
          secretsFile = "/etc/datomic-pro/do-not-do-this.properties";
          settings = {
            host = "localhost";
            port = 4334;
            protocol = "dev";
            storage-access = "remote";
            # the follow memory tweaks are only for the test env
            memory-index-max = "64m";
            memory-index-threshold = "16m";
            object-cache-max = "64m";
          };
        };

        environment.etc."datomic-console/do-not-do-this" = {
          text = "datomic:dev://localhost:4334/?password=do-not-do-it-this-way-in-prod-peer";
          mode = "0600";
        };
        services.datomic-console = {
          enable = true;
          alias = "dev";
          port = 8080;
          dbUriFile = "/etc/datomic-console/do-not-do-this";
        };
        environment.systemPackages = [
          pkgs.clojure
          pkgs.vim
          pkgs.bash
          package
        ];
        users.users.root = {
          hashedPassword = lib.mkForce null;
          hashedPasswordFile = lib.mkForce null;
          initialPassword = lib.mkForce null;
          password = lib.mkForce "root";
        };
        environment.etc."datomic-test/deps.edn" = {
          mode = "0600";
          text = ''
            {:paths   ["."]
             :deps    {com.datomic/peer {:local/root "${package}/share/datomic-pro/peer-${version}.jar"}}
             :aliases {:run {:jvm-opts  ["-Ddatomic.uri=datomic:dev://localhost:4334/test-db?password=do-not-do-it-this-way-in-prod-peer"]
                             :main-opts ["-m" "hello"]}}}
          '';
        };
        environment.etc."datomic-test/hello.clj" = {
          mode = "0600";
          text = builtins.readFile ./fixtures/hello.clj;
        };
      };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("datomic-pro.service")
    machine.wait_for_open_port(4334)
    machine.wait_until_succeeds("journalctl -u datomic-pro -o cat | grep -q 'System started'")

    # Note: running the clojure test requires internet, because maven deps will be downloaded
    #       unfortunately the datomic distribution does not include all deps for the peer lib.
    machine.succeed("cd /etc/datomic-test && clojure -M:run")

    machine.wait_for_unit("datomic-console.service")
    machine.wait_for_open_port(8080)

    machine.succeed("curl --fail http://localhost:8080/browse")

    print(machine.succeed("datomic-run -m datomic.integrity 'datomic:dev://localhost:4334/test-db?password=do-not-do-it-this-way-in-prod-peer'"))

  '';
}
