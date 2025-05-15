{
  babashka,
  fetchzip,
  jdk21_headless,
  jre,
  lib,
  makeWrapper,
  stdenv,
  extraLibs ? [ ], # native libs will be added to datomic's library path
  extraJavaPkgs ? [ ], # jars contained in share/java will be added to datomic's class path
  withCustomJre ? false, # set to true to built a custom jre with only the required modules
  overrideJre ? null, # provide your own jre/jdk package that datomic-pro will use
  ...
}:

stdenv.mkDerivation (
  finalAttrs:
  let
    jdk = jdk21_headless;
    actualJre =
      if withCustomJre then "$out/jre" else (if overrideJre != null then "${overrideJre}" else "${jre}");
    classpath = "$out/share/datomic-pro/resources:$out/lib/datomic-transactor-pro-${finalAttrs.version}.jar:$out/share/datomic-pro/lib/*:$out/share/datomic-pro/samples/clj:$out/share/datomic-pro/bin";
    libpath = lib.makeLibraryPath extraLibs;
  in
  {
    pname = "datomic-pro";
    version = "1.0.7364";

    src = fetchzip {
      url = "https://datomic-pro-downloads.s3.amazonaws.com/${finalAttrs.version}/datomic-pro-${finalAttrs.version}.zip";
      hash = "sha256-y9jSA4s0aEn9QheZ3YBDtx8wTqOv+9XJXwzyW9R5T4w=";
    };
    nativeBuildInputs =
      [
        makeWrapper
      ]
      ++ lib.optionals withCustomJre [
        jdk
        babashka
      ];
    dontConfigure = true;
    dontBuild = !withCustomJre;

    stripDebugFlags = lib.optionals withCustomJre [ "--strip-unneeded" ];

    buildPhase = lib.optionalString withCustomJre ''
      runHook preBuild
      # Create a temporary file to store the jdeps output
      mkdir -p tmp

      # Scan all jar files and analyze their dependencies
      find lib -name "*.jar" -exec bash -c "${jdk}/bin/jdeps --multi-release base --ignore-missing-deps --print-module-deps {} >> tmp/modules.txt" \;

      ${jdk}/bin/jdeps --ignore-missing-deps --print-module-deps datomic-transactor*.jar >> tmp/modules.txt
      # Combine all unique modules into a comma delimited string
      modules=$(${babashka}/bin/bb -e '(print (str/join "," (->> (slurp *in*) str/split-lines (mapcat #(str/split % #",")) distinct (remove str/blank?))))' < tmp/modules.txt)

      rm -rf tmp
      # Build the minimal JRE with the detected modules
      jlink --module-path ${jdk}/lib/openjdk/jmods \
            --no-man-pages \
            --no-header-files \
            --add-modules "$modules" \
            --output $out/jre

      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/{bin,lib,share}
      mv *transactor*.jar $out/lib/
      rm -rf peer*.jar presto-server
      mkdir -p $out/share/datomic-pro
      cp -R * $out/share/datomic-pro/
      mv $out/share/datomic-pro/bin/logback.xml $out/share/datomic-pro/logback-sample.xml

      install_jars() {
        if [ -d "$1" ]; then
          find "$1/share/java" -type f \(  -iname \*.jar \) -exec install -m 0500 "{}" "$out/share/datomic-pro/lib/" \;
        else
          install -m 0500 "$1" "$out/share/datomic-pro/lib/"
        fi
      }
      ${lib.concatMapStringsSep "\n" (pl: "install_jars ${lib.escapeShellArg pl}") extraJavaPkgs}

      makeWrapper ${actualJre}/bin/java $out/bin/datomic-transactor \
        --set-default "JAVA_OPTS" "-XX:+UseG1GC -XX:MaxGCPauseMillis=50 -Djava.library.path=\$LD_LIBRARY_PATH" \
        --set-default "DATOMIC_JAVA_OPTS" "" \
        --prefix LD_LIBRARY_PATH : "${libpath}" \
        --prefix CLASSPATH : "${classpath}" \
        --add-flags "\$JAVA_OPTS" \
        --add-flags "\$DATOMIC_JAVA_OPTS" \
        --add-flags "-server" \
        --add-flags "clojure.main" \
        --add-flags "--main" \
        --add-flags "datomic.launcher"

      makeWrapper ${actualJre}/bin/java $out/bin/datomic-console \
        --chdir "$out/share/datomic-pro" \
        --prefix CLASSPATH : "$out/share/datomic-pro/lib/console/*:${classpath}" \
        --add-flags "-server" \
        --set-default "JAVA_OPTS" "-Xmx1g" \
        --set-default "DATOMIC_JAVA_OPTS" "" \
        --add-flags "\$JAVA_OPTS" \
        --add-flags "\$DATOMIC_JAVA_OPTS" \
        --add-flags "clojure.main" \
        --add-flags "-i" \
        --add-flags "$out/share/datomic-pro/bin/bridge.clj" \
        --add-flags "--main" \
        --add-flags "datomic.console"

      makeWrapper ${actualJre}/bin/java $out/bin/datomic-shell \
        --chdir "$out/share/datomic-pro" \
        --prefix CLASSPATH : "${classpath}" \
        --add-flags "-server" \
        --set-default "JAVA_OPTS" "-Xmx1g" \
        --set-default "DATOMIC_JAVA_OPTS" "" \
        --add-flags "\$JAVA_OPTS" \
        --add-flags "\$DATOMIC_JAVA_OPTS" \
        --add-flags jline.ConsoleRunner \
        --add-flags clojure.main \
        --add-flags "$out/share/datomic-pro/bin/shell.clj"

      makeWrapper ${actualJre}/bin/java $out/bin/datomic-run \
        --chdir "$out/share/datomic-pro" \
        --prefix CLASSPATH : "${classpath}" \
        --add-flags "-server" \
        --set-default "JAVA_OPTS" "-Xmx1g -Xms1g" \
        --set-default "DATOMIC_JAVA_OPTS" "" \
        --add-flags "\$JAVA_OPTS" \
        --add-flags "\$DATOMIC_JAVA_OPTS" \
        --add-flags "clojure.main" \
        --add-flags "-i" \
        --add-flags "$out/share/datomic-pro/bin/bridge.clj"

      makeWrapper $out/bin/datomic-run $out/bin/datomic-repl \
        --add-flags "-r" \
        --add-flags "datomic.repl"
      makeWrapper $out/bin/datomic-run $out/bin/datomic-peer-server \
        --add-flags "-m" \
        --add-flags "datomic.peer-server"
      runHook postInstall
    '';
    meta = {
      description = "A transactional database with a flexible data model, elastic scaling, and rich queries.";
      homepage = "https://docs.datomic.com/releases-pro.html";
      changelog = "https://docs.datomic.com/changes/pro.html";
      license = lib.licenses.asl20;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      mainProgram = "datomic-transactor";
    };
  }
)
