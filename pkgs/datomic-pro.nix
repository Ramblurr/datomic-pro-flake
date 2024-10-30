{
  lib,
  stdenv,
  fetchzip,
  jdk21_headless,
  sqlite-jdbc,
  postgresql_jdbc,
  mysql_jdbc,
  enableSqlite ? true,
  # datomic upstream comes with the postgresql jdbc jar, you can override it with the nixpkgs version by setting this true
  # in either case *a* postgresql jdbc jar will be included
  enablePostgresql ? false,
  enableMysql ? true,
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
    chmod -R u+w $out/lib
    ${lib.optionalString enableSqlite ''
      cp ${sqlite-jdbc}/share/java/*.jar $out/lib/
    ''}
    ${lib.optionalString enableMysql ''
      cp ${mysql_jdbc}/share/java/*.jar $out/lib/
    ''}
    ${lib.optionalString enablePostgresql ''
      rm $out/lib/postgresql*.jar
      cp ${postgresql_jdbc}/share/java/*.jar $out/lib/
    ''}
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
