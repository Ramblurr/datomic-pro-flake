{
  babashka,
  bash,
  bashInteractive,
  cacert,
  coreutils,
  datomic-generate-properties,
  datomic-pro,
  dockerTools,
  fetchzip,
  hostname,
  imageTag,
  jdk21_headless,
  lib,
  mysql_jdbc,
  runCommand,
  sqlite-jdbc,
  stdenv,
  writeShellScriptBin,
  ## TODO: remove these, they are only for testing
  sqlite-interactive,
  gnugrep,
  which,
  findutils,
  vim,
  ...
}:

let
  jdk = jdk21_headless;

  datomicBuild = datomic-pro.override {
    extraJavaPkgs = [
      sqlite-jdbc
      mysql_jdbc
    ];
  };
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
      ${datomicBuild}/bin/datomic-console -p 8080 dev "$DB_URI"
    else
      if [ -z "$DOCKER_DATOMIC_GENERATE_PROPERTIES_SKIP" ]; then
        echo "Generating Datomic Properties"
        ${datomic-generate-properties}/bin/datomic-generate-properties
      else
        echo "Skipping Datomic Properties Generation"
      fi
      echo "Starting Datomic Transactor..."
      ${datomicBuild}/bin/datomic-transactor "$DATOMIC_TRANSACTOR_PROPERTIES_PATH"
    fi
  '';
  env-shim = runCommand "env-shim" { } ''
    mkdir -p $out/usr/bin
    ln -s ${coreutils}/bin/env $out/usr/bin/env
    # conveniently symlink these in place so an admin can access them with podman run -it
    for cmd in transactor console shell run repl; do
      ln -s ${datomicBuild}/bin/datomic-$cmd $out/usr/bin/datomic-$cmd
    done
  '';
in
dockerTools.buildLayeredImage {
  name = "ghcr.io/ramblurr/datomic-pro";
  tag = imageTag;
  fromImage = null;
  contents = [
    babashka
    bashInteractive
    cacert
    coreutils
    datomic-generate-properties
    datomicBuild
    entrypoint
    env-shim
    jdk
    mysql_jdbc
    sqlite-jdbc
    ## TODO: remove these, they are only for testing
    sqlite-interactive
    gnugrep
    which
    findutils
    vim
  ];
  extraCommands = ''
    mkdir -p tmp
    chmod 1777 tmp
  '';

  config = {
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
      "org.opencontainers.image.version" = datomicBuild.version;
      "org.opencontainers.image.licenses" = "Apache-2.0";
    };
    Volumes = {
      "/config" = { };
      "/data" = { };
    };
  };
}
