{
  lib,
  stdenv,
  fetchzip,
  jdk21_headless,
  ...
}:

let
in

stdenv.mkDerivation (finalAttrs: {
  pname = "datomic-pro";
  version = "1.0.7260";

  src = fetchzip {
    url = "https://datomic-pro-downloads.s3.amazonaws.com/${finalAttrs.version}/datomic-pro-${finalAttrs.version}.zip";
    sha256 = "sha256-J3uGNOcA2JsHGecQbnS2w57XCfiF3H0FNcBJ+vB/OYE=";
  };
  propagatedBuildInputs = [ jdk21_headless ];
  installPhase = ''
    runHook preInstall
    ls -al $src
    mkdir -p $out
    cp -r $src/* $out
    find $out
    runHook postInstall
  '';
  meta = {
    description = "Datomic Pro";
    homepage = "https://docs.datomic.com/releases-pro.html";
    changelog = "https://docs.datomic.com/changes/pro.html";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "transactor";
  };
})
