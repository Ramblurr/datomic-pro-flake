{
  lib,
  maven,
  fetchzip,
  stdenv,
  jre,
  jdk,
  ...
}:

stdenv.mkDerivation (
  finalAttrs:
  let
    pname = "datomic-pro-peer";
    version = "1.0.7260";
    mvnHash = "sha256-09AKaahc4MSc0d/gWJyMpB60O7WZOauj7vS1X4rtPjI=";
    zipHash = "sha256-J3uGNOcA2JsHGecQbnS2w57XCfiF3H0FNcBJ+vB/OYE=";
    manualMvnSources = [ ];
    manualMvnArtifacts = [ ];
    dependencies = stdenv.mkDerivation ({
      name = "datomic-peer-${version}-maven-deps";

      src = fetchzip {
        url = "https://datomic-pro-downloads.s3.amazonaws.com/${version}/datomic-pro-${version}.zip";
        hash = zipHash;
      };

      nativeBuildInputs = [
        maven
      ];

      JAVA_HOME = jdk;

      buildPhase = ''
        runHook preBuild
        mvn de.qaware.maven:go-offline-maven-plugin:1.2.8:resolve-dependencies -Dmaven.repo.local=$out/.m2

        for artifactId in ${builtins.toString manualMvnArtifacts}
        do
          echo "downloading manual $artifactId"
          mvn dependency:get -Dartifact="$artifactId" -Dmaven.repo.local=$out/.m2
        done

        for artifactId in ${builtins.toString manualMvnSources}
        do
          group=$(echo $artifactId | cut -d':' -f1)
          artifact=$(echo $artifactId | cut -d':' -f2)
          echo "downloading manual sources $artifactId"
          mvn dependency:sources -DincludeGroupIds="$group" -DincludeArtifactIds="$artifact" -Dmaven.repo.local=$out/.m2
        done
        runHook postBuild
      '';

      # keep only *.{pom,jar,sha1,nbm} and delete all ephemeral files with lastModified timestamps inside
      installPhase = ''
        runHook preInstall

        find $out -type f \( \
          -name \*.lastUpdated \
          -o -name resolver-status.properties \
          -o -name _remote.repositories \) \
          -delete


        mkdir -p $out/share/java
        mvn org.apache.maven.plugins:maven-dependency-plugin:3.6.1:copy-dependencies \
          -DoutputDirectory=$out/share/java \
          -DincludeScope=runtime \
          -Dmaven.repo.local=$out/.m2

        rm -rf $out/.m2

        runHook postInstall
      '';

      # don't do any fixup
      dontFixup = true;
      outputHashAlgo = if mvnHash != "" then null else "sha256";
      outputHashMode = "recursive";
      outputHash = mvnHash;
    });
  in
  {
    pname = pname;
    version = version;
    src = dependencies.src;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/java

      for jar in ${dependencies}/share/java/*.jar; do
        ln -s "$jar" $out/share/java/$(basename "$jar")
      done

      install -Dm444 peer-${version}.jar $out/share/java/datomic-pro-peer-${version}.jar
      runHook postInstall
    '';

    meta = {
      description = "The peer library for the Datomic database";
      homepage = "https://docs.datomic.com/releases-pro.html";
      changelog = "https://docs.datomic.com/changes/pro.html";
      license = lib.licenses.asl20;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };

  }
)
