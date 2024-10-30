check:
	nix flake check
test: check

datomic-pro:
	nix build .#datomic-pro -o result --show-trace

datomic-pro-container:
	nix build .#datomic-pro-container -o container --show-trace

clean:
	rm -rf result container
