{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.datomic-console;
  logbackConfigFile = pkgs.writeText "logback.xml" cfg.logbackConfig;
  extraJavaOptions =
    cfg.extraJavaOptions
    ++ lib.optional (cfg.logbackConfig != "") "-Dlogback.configurationFile=${logbackConfigFile}";
  extraClasspath = lib.concatStringsSep ":" cfg.extraClasspathEntries;
in
{
  options = {
    services.datomic-console = {
      enable = lib.mkEnableOption "Datomic Console";
      package = lib.mkPackageOption pkgs "datomic-pro" { };
      port = lib.mkOption {
        type = lib.types.port;
        description = "The port the console will bind to";
      };
      alias = lib.mkOption {
        type = lib.types.str;
        default = "dev";
        description = "A text-based name for a transactor that is associated with a transactor URI that does not include a database name";
      };
      dbUriFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to a file containing the 'datomic:' database uri

          Should be owned by root and have 0600 permissions.
        '';
      };

      stateDirectoryName = lib.mkOption {
        type = lib.types.str;
        default = "datomic-console";
        description = "The name of the directory under /var/lib that will be used as the state directory for datomic.";
      };

      extraJavaOptions = lib.mkOption {
        description = "Extra command line options for Java.";
        default = [ ];
        type = lib.types.listOf lib.types.str;
        example = [
          "-Dfoo=bar"
          "-Xbaz=bar"
        ];
      };
      extraClasspathEntries = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Extra entries added to the Java classpath when running Datomic Console
        '';
        example = [
          "/path/to/my.jer"
          "/path/to/folder/of/jars/*"
        ];
      };
      logbackConfig = lib.mkOption {
        type = lib.types.lines;
        default = ''
          <configuration>

            <!-- prevent per-message overhead for jul logging calls, e.g. Hornet -->
            <contextListener class="ch.qos.logback.classic.jul.LevelChangePropagator">
              <resetJUL>true</resetJUL>
            </contextListener>

            <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
                <encoder>
                  <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level %-10contextName %logger{36} - %msg%n</pattern>
                </encoder>
            </appender>

            <logger name="datomic.cast2slf4j" level="DEBUG"/>

            <!-- uncomment to log storage access -->
            <!-- <logger name="datomic.kv-cluster" level="DEBUG"/> -->

            <!-- uncomment to log transactor heartbeat -->
            <!-- <logger name="datomic.lifecycle" level="DEBUG"/> -->

            <!-- uncomment to log transactions (transactor side) -->
            <!-- <logger name="datomic.transaction" level="DEBUG"/> -->

            <!-- uncomment to log transactions (peer side) -->
            <!-- <logger name="datomic.peer" level="DEBUG"/> -->

            <!-- uncomment to log the transactor log -->
            <!-- <logger name="datomic.log" level="DEBUG"/> -->

            <!-- uncomment to log peer connection to transactor -->
            <!-- <logger name="datomic.connector" level="DEBUG"/> -->

            <!-- uncomment to log storage gc -->
            <!-- <logger name="datomic.garbage" level="DEBUG"/> -->

            <!-- uncomment to log indexing jobs -->
            <!-- <logger name="datomic.index" level="DEBUG"/> -->

            <!-- these namespsaces create a ton of log noise -->
            <logger name="org.apache.activemq.audit" level="WARN"/>
            <logger name="httpclient" level="INFO"/>
            <logger name="org.apache.commons.httpclient" level="INFO"/>
            <logger name="org.apache.http" level="INFO"/>
            <logger name="org.jets3t" level="INFO"/>
            <logger name="com.amazonaws" level="INFO"/>
            <logger name="com.amazonaws.request" level="WARN"/>
            <logger name="sun.rmi" level="INFO"/>
            <logger name="datomic.spy.memcached" level="INFO"/>
            <logger name="com.couchbase.client" level="INFO"/>
            <logger name="com.ning.http.client.providers.netty" level="INFO"/>
            <logger name="org.eclipse.jetty" level="INFO"/>
            <logger name="org.hornetq.core.client.impl" level="INFO"/>
            <logger name="org.apache.tomcat.jdbc.pool" level="INFO"/>
            <logger name="datomic.cast2slf4j" level="DEBUG"/>

            <root level="info">
              <appender-ref ref="STDOUT"/>
            </root>
          </configuration>
        '';
        description = ''
          XML logback configuration for the datomic-pro transactor.
        '';
      };

    };
  };
  config = lib.mkIf cfg.enable {

    assertions = [
      {
        assertion = lib.strings.hasInfix "/" cfg.stateDirectoryName == false;
        message = ''
          <option>services.datomic-console.stateDirectoryName> must be a single directory name, not a path with /.
        '';
      }
    ];
    systemd.services.datomic-console = {
      description = "Datomic Console";
      wantedBy = [ "multi-user.target" ];
      script = ''
        db_uri="$(<"$CREDENTIALS_DIRECTORY/datomic-console-db-uri")"
        ${cfg.package}/bin/datomic-console -p ${toString cfg.port} "${cfg.alias}" "$db_uri"
      '';
      environment =
        {
          DATOMIC_JAVA_OPTS = toString extraJavaOptions;
        }
        // lib.optionalAttrs (cfg.extraClasspathEntries != [ ]) {
          CLASSPATH = extraClasspath;
        };
      serviceConfig = {
        Type = "simple";
        LoadCredential = [ "datomic-console-db-uri:${cfg.dbUriFile}" ];
        DynamicUser = true;
        StateDirectory = cfg.stateDirectoryName;
        Restart = "always";
        MemoryDenyWriteExecute = false; # required for the jvm
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectKernelLogs = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        SystemCallArchitectures = "native";
      };
    };
  };
}
