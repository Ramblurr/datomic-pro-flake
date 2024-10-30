{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.datomic-pro;
  settingsFormat = pkgs.formats.javaProperties { };
  stateDir = "/var/lib/${cfg.stateDirectoryName}";
  runtimePropertiesPath = "${stateDir}/transactor.properties";
  # default settings that will be used unless overriden by the user
  settingsDefault = {
    host = "localhost";
    memory-index-max = "256m";
    memory-index-threshold = "32m";
    object-cache-max = "128m";
    port = 4334;
    protocol = "dev";
    data-dir = "${stateDir}/data";
    log-dir = "${stateDir}/log";
  };
  propertiesFile = settingsFormat.generate "transactor.properties" (settingsDefault // cfg.settings);
in
{
  options = {
    services.datomic-pro = {
      enable = lib.mkEnableOption "Datomic Pro";
      package = lib.mkPackageOption pkgs "datomic-pro" { };
      javaPackage = lib.mkPackageOption pkgs "jdk21_headless" { };
      secretsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Secret configuration concatenated to the transactor properties at runtime.

          Should be owned by root and have 0600 permissions.
        '';
      };

      stateDirectoryName = lib.mkOption {
        type = lib.types.str;
        default = "datomic-pro";
        description = "The name of the directory under /var/lib that will be used as the state directory for datomic.";
      };

      settings = lib.mkOption {
        type = lib.types.submodule { freeformType = settingsFormat.type; };
        default = {
          host = "localhost";
          memory-index-max = "256m";
          memory-index-threshold = "32m";
          object-cache-max = "128m";
          port = 4334;
          protocol = "dev";
          data-dir = "${stateDir}/data";
          log-dir = "${stateDir}/log";
        };
        description = ''
          Configuration written to `transactor.properties`.

          The default configuration will run the transactor in dev mode.

          ::: {.note}
          Do not specify secrets, password, etc in this config block as it is written to the globally readable nix store. For those properties use `secretSettingsFile`.
        '';
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.strings.hasInfix "/" cfg.stateDirectoryName == false;
        message = ''
          <option>services.datomic-pro.stateDirectoryName> must be a single directory name, not a path with /.
        '';
      }
    ];
    systemd.services.datomic-pro = {
      description = "Datomic Pro";
      wantedBy = [ "multi-user.target" ];
      path = [ cfg.javaPackage ];
      preStart = ''
        cat ${propertiesFile} > ${runtimePropertiesPath}
        chmod 0600 ${runtimePropertiesPath}
        ${lib.optionalString (cfg.secretsFile != null) ''
          cat $CREDENTIALS_DIRECTORY/datomic-pro-secrets >> ${runtimePropertiesPath}
        ''}
        mkdir -p ${stateDir}/data ${stateDir}/log
      '';
      script = ''
        ${cfg.package}/bin/datomic-transactor ${runtimePropertiesPath}
      '';
      environment = {
        DATOMIC_JAVA_OPTS = "-Dlogback.configurationFile ${cfg.package}/share/datomic-pro/logback-sample.xml";
      };
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        StateDirectory = cfg.stateDirectoryName;
        LoadCredential = lib.mkIf (cfg.secretsFile != null) [ "datomic-pro-secrets:${cfg.secretsFile}" ];
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
