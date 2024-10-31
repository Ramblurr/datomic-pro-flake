{
  hostname,
  lib,
  mkBabashka,
  stdenv,
  substituteAll,
  ...
}:

stdenv.mkDerivation (
  finalAttrs:
  let
    bb = mkBabashka {
      bbLean = true;
      wrap = false;
      withFeatures = [ "transit" ];
    };
  in
  {
    pname = "datomic-generate-properties";
    version = "0.1";

    src = substituteAll {
      babashkaBin = "${bb}/bin/bb";
      src = ./generate-properties.clj;
    };

    dontUnpack = true;
    propagatedBuildInputs = [
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
  }
)
