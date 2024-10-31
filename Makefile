DOCKER ?= docker

check:
	nix --print-build-logs flake check

test/nixos:
	nix --print-build-logs run '.#checks.x86_64-linux.moduleTest.driver'
test/container:
	nix --print-build-logs run '.#checks.x86_64-linux.containerImageTest.driver'

test: test/nixos test/container

datomic-pro:
	nix build .#datomic-pro -o result --show-trace

test/pkg-dev: datomic-pro
	 mkdir -p data
	./result/bin/datomic-transactor tests/fixtures/testdev.properties

test/pkg-sql: datomic-pro
	 mkdir -p data
	./result/bin/datomic-transactor tests/fixtures/testsql.properties

test/pkg-console-dev: datomic-pro
	./result/bin/datomic-console -p 8080 app 'datomic:dev://localhost:4334/?password=datpass'

test/pkg-console-sql: datomic-pro
	./result/bin/datomic-console -p 8080 app 'datomic:sql://?jdbc:sqlite:data/db-sqlite.db'

datomic-pro-container:
	nix build .#datomic-pro-container -o datomic-pro-container --show-trace

datomic-pro-container-unstable:
	nix build .#datomic-pro-container-unstable -o datomic-pro-container-unstable --show-trace

clean:
	rm -f result container datomic-pro-container-unstable datomic-pro-container
	rm -rf data/

load: datomic-pro-container-unstable
	$(DOCKER) load < ./datomic-pro-container-unstable
