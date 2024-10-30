{
  imageTag,
  lib,
  stdenv,
  fetchzip,
  dockerTools,
  datomic-pro,
  datomic-generate-properties,
  writeShellScriptBin,
  cacert,
  bashInteractive,
  coreutils,
  jdk21_headless,
  babashka,
  hostname,
  bash,
  ...
}:

let
  jdk = jdk21_headless;
  entrypoint = writeShellScriptBin "datomic-entrypoint" ''
    set -e
    export PATH=${bash}/bin:${hostname}/bin:${jdk}/bin:${coreutils}/bin:${babashka}:$PATH
    if [ "$(id -u)" = "0" ]; then
      echo "WARNING: Running Datomic as root is not recommended. Please run as a non-root user."
      echo "         This can be ignored if you are using rootless mode."
    fi
    if [ "$1" = "console" ]; then
      echo "Starting Datomic Console..."
      if [ -n "$DB_URI_FILE" ] && [ -f "$DB_URI_FILE" ]; then
        DB_URI=$(cat "$DB_URI_FILE")
      fi
      if [ -z "$DB_URI" ]; then
        echo "DB_URI is not set. Please set DB_URI environment variable or provide a file path with DB_URI_FILE."
        exit 1
      fi
      ${datomic-pro}/bin/console -p 8080 dev "$DB_URI"
    else
      echo "Generating Datomic Properties"
      ${datomic-generate-properties}/bin/datomic-generate-properties
      echo "Starting Datomic Transactor..."
      ${datomic-pro}/bin/transactor "$DATOMIC_TRANSACTOR_PROPERTIES_PATH"
    fi
  '';
in
dockerTools.buildLayeredImage {
  name = "ghcr.io/ramblurr/datomic-pro";
  tag = imageTag;
  fromImage = null;
  contents = [
    datomic-pro
    entrypoint
    datomic-generate-properties
    bashInteractive
    coreutils
    babashka
    jdk
    cacert
  ];
  config = {
    WorkingDir = datomic-pro;
    Entrypoint = [ "${entrypoint}/bin/datomic-entrypoint" ];

    Env = [
      "DATOMIC_TRANSACTOR_PROPERTIES_PATH=/config/transactor.properties"
      "LC_ALL=C.UTF-8"
      "LANG=C.UTF-8"
      "UMASK=0002"
      "TZ=Etc/UTC"
    ];
    Labels = {
      "org.opencontainers.image.authors" = "github.com/ramblurr";
      "org.opencontainers.image.url" = "https://github.com/Ramblurr/datomic-pro-flake/tree/main/pkgs/datomic-pro-container-image.nix";
      "org.opencontainers.image.source" = "https://github.com/Ramblurr/datomic-pro-flake";
      "org.opencontainers.image.description" = "Datomic Pro";
      "org.opencontainers.image.version" = datomic-pro.version;
      "org.opencontainers.image.licenses" = "Apache-2.0";
    };
    Volumes = {
      "/config" = { };
      "/data" = { };
    };
  };
}
