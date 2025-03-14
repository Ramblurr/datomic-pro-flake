#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash nix curl coreutils jq common-updater-scripts
set -euo pipefail
# so far the transactor has been released in lockstep with the peer, so we can fetch the version from maven.
latestVersion=$(curl -s "https://repo.maven.apache.org/maven2/com/datomic/peer/maven-metadata.xml" | grep -oP '<latest>\K[^<]+')
currentVersion=$(nix eval --raw .#datomic-pro.version)
currentVersionPeer=$(nix eval --raw .#datomic-pro-peer.version)

echo "Latest Datomic Pro version  : $latestVersion"
echo "Current version (transactor): $currentVersion"
echo "Current version (peer)      : $currentVersionPeer"

if [[ "$latestVersion" == "$currentVersion" ]] && [[ "$latestVersion" == "$currentVersionPeer" ]]; then
    echo "Package is up-to-date"
    exit 0
fi

url="https://datomic-pro-downloads.s3.amazonaws.com/$latestVersion/datomic-pro-$latestVersion.zip";
prefetch=$(nix-prefetch-url "$url")
hash=$(nix hash convert --hash-algo sha256 --to sri $prefetch)

if [[ "$latestVersion" != "$currentVersion" ]]; then
  drift rewrite --verbose  datomic-pro  --file ./pkgs/datomic-pro.nix --new-version "$latestVersion" --new-hash "$hash" --name datomic-pro --current-version "$currentVersion"
  echo "Updated datomic-pro from $currentVersion to $latestVersion"
fi


if [[ "$latestVersion" != "$currentVersionPeer" ]]; then
  drift rewrite --verbose  datomic-pro-peer  --file ./pkgs/datomic-pro-peer.nix --new-version "$latestVersion" --new-hash "$hash" --name datomic-pro-peer --current-version "$currentVersion"
  echo "Updated datomic-pro-peer from $currentVersion to $latestVersion"
fi
