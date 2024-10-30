DOCKER ?= docker

check:
	nix flake check
test: check

datomic-pro:
	nix build .#datomic-pro -o result --show-trace

datomic-pro-container:
	nix build .#datomic-pro-container -o datomic-pro-container --show-trace

datomic-pro-container-unstable:
	nix build .#datomic-pro-container-unstable -o datomic-pro-container-unstable --show-trace

clean:
	rm -f result container datomic-pro-container-unstable datomic-pro-container

load: datomic-pro-container-unstable
	$(DOCKER) load < ./datomic-pro-container-unstable
