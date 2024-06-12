# datomic-pro-flake

[![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/ramblurr/datomic-pro/badge)](https://flakehub.com/flake/ramblurr/datomic-pro)
[![GitHub License](https://img.shields.io/github/license/ramblurr/datomic-pro-flake)](./LICENSE)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/ramblurr/datomic-pro-flake/ci.yml)](https://github.com/Ramblurr/datomic-pro-flake/actions/workflows/ci.yml)

❄️ This flake exposes a `datomic-pro` nix package and several NixOS modules for running Datomic Pro on NixOS.

> 🐋 Looking for a container / docker image instead? Check out my other repo [ramblurr/containers](https://github.com/Ramblurr/containers/tree/main/apps/datomic-pro).

## Usage

### `flake.nix`

```nix
{
  inputs.
   inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        datomic-pro.url = "https://flakehub.com/f/Ramblurr/datomic-pro/*.tar.gz";
        datomic-pro.nixpkgs = "nixpkgs";
    };
    outputs = { nixpkgs, datomic-pro, ... }@attrs: {
        nixosConfigurations.machine = nixpksg.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
                ./configuration.nix
                datomic-pro.nixosModules.${system}.datomic-pro
            ];
        };
    };
}

```

### `/etc/datomic-pro/secrets.properties`

I wouldn't really do this in production I would use a tool like
[agenix](https://github.com/ryantm/agenix) or
[sops-nix](https://github.com/Mic92/sops-nix).

Whatever you do, do not use
[`environment.etc`](https://search.nixos.org/options?channel=24.05&show=environment.etc&from=0&size=50&sort=relevance&type=packages&query=environment.etc)
to create the secret files! That will write the secrets into the globally
readable nix store, and could end up on a nix cache somewhere. Bad news!

``` java-properties
# in `/etc/datomic-pro/secrets.properties`
storage-admin-password=changeme
storage-datomic-password=changeme
```

``` shell
# set permissions carefully, it just needs to be root owned
# even though datomic doesn't run as root (thanks systemd!)
chown root:root /etc/datomic-pro/secrets.properties
chmod 0600 /etc/datomic-pro/secrets.properties
```

### `configuration.nix`

A basic dev-mode datomic that stores its state in `/var/lib/datomic-pro`:

``` nix
{
    services.datomic-pro = {
        secretsFile = "/etc/datomic-pro/secrets.properties";
        settings = {
            # no secrets in here!
            enable = true;
            host = "localhost";
            port = 4334;
            memory-index-max = "256m";
            memory-index-threshold = "32m";
            object-cache-max = "128m";
            protocol = "dev";
            storage-access = "remote";
        };
    }
    # optionally add the console

    services.datomic-console = {
        enable = true;
        port = 8080;
        dbUriFile = ..path to secret file containing something like datomic:dev://localhost:4334/.....
    };

    # ... the rest of your owl ...
}
```

### Discussion

Feel free to [open an issue](https://github.com/Ramblurr/datomic-pro-flake/issues/new) or reach out to me on the Clojurians slack ([@Ramblurr](https://clojurians.slack.com/team/U70QFSCG2)).

## License

The contents of this flake is licensed under the Apache-2.0, just like Datomic Pro itself.

```
Copyright 2024 Casey Link

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
