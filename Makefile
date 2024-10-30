DOCKER ?= docker

check:
	nix flake check
test: check


datomic-pro:
	nix build .#datomic-pro -o result --show-trace

test-pkg: datomic-pro
	./result/bin/datomic-transactor testsql.properties
	#./result/bin/datomic-transactor ./result/share/datomic-pro/config/samples/dev-transactor-template.properties

test-pkg-console: datomic-pro
	./result/bin/datomic-console -p 8080 app datomic:dev://localhost:4334/

datomic-pro-container:
	nix build .#datomic-pro-container -o datomic-pro-container --show-trace

datomic-pro-container-unstable:
	nix build .#datomic-pro-container-unstable -o datomic-pro-container-unstable --show-trace

clean:
	rm -f result container datomic-pro-container-unstable datomic-pro-container
	rm -rf data/

load: datomic-pro-container-unstable
	$(DOCKER) load < ./datomic-pro-container-unstable
