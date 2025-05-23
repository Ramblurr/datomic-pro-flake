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

url="https://datomic-pro-downloads.s3.amazonaws.com/$latestVersion/datomic-pro-$latestVersion.zip"
prefetch=$(nix-prefetch-url "$url")
echo prefetch: "$prefetch"
hash=$(nix hash convert --hash-algo sha256 --to sri "$prefetch")
version_=${latestVersion//./_}

echo "New hash: $hash"
echo
echo
cat <<EOF
  datomic-pro_${version_} = pkgs.callPackage ./datomic-pro.nix {
    version = "${latestVersion}";
    hash = "${hash}";
  };
EOF
