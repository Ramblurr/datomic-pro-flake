{
  lib,
  stdenv,
  fetchzip,
  babashka,
  dockerTools,
  datomic-pro,
  hostname,
  ...
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "datomic-generate-properties";
  version = "0.1";

  src = ./generate-properties.clj;

  dontUnpack = true;
  propagatedBuildInputs = [
    babashka
    hostname
  ];
  installPhase = ''
    runHook preInstall
    ls -al $src
    mkdir -p $out/bin
    cp -r $src $out/bin/datomic-generate-properties
    chmod +x $out/bin/datomic-generate-properties
    find $out
    runHook postInstall
  '';
  meta = {
    description = "Generates a java properties file for Datomic Pro based off of environment variables and sane defaults.";
    homepage = "";
    changelog = "";
    license = lib.licenses.asl20;
    mainProgram = "datomic-generate-properties";
  };
})
