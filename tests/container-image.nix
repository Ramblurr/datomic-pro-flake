{
  self,
  system,
  pkgs,
  nixpkgs,
}:

with import (nixpkgs + "/nixos/lib/testing-python.nix") { inherit system pkgs; };
with pkgs.lib;

makeTest {
  name = "datomic-pro dev-mode container test";
  nodes = {
    docker =
      { ... }:
      {
        nixpkgs.overlays = [ self.overlays."${system}" ];
        virtualisation = {
          diskSize = 8192;
          memorySize = 2048;
          docker.enable = true;
        };
        environment.systemPackages = with pkgs; [ jq ];
      };
  };

  testScript = ''
    start_all()
    docker.wait_for_unit("sockets.target")
    docker.succeed(
      "docker load --input='${pkgs.datomic-pro-container}'"
    )

    docker.succeed("rm -rf ./data && mkdir ./data")
    docker.succeed(
      """
      docker run -d --name datomic -v ./data:/data -p 4335:4334 -e DATOMIC_STORAGE_ADMIN_PASSWORD=unsafe -e DATOMIC_STORAGE_DATOMIC_PASSWORD=unsafe ghcr.io/ramblurr/datomic-pro:${pkgs.datomic-pro.version}
      """
    )
    docker.wait_for_open_port(4335)
    def try_logs(_) -> bool:
      status, _ = docker.execute("docker logs datomic | grep -q 'System started'")
      return status == 0
    with docker.nested("waiting for datomic to start"):
      retry(try_logs)
    docker.wait_for_file("./data/db/datomic.trace.db")
    docker.succeed("docker rm -f datomic")
    docker.wait_for_closed_port(4335)
  '';
}
