{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.datomic-console;
in
{
  options = {
    services.datomic-console = {
      enable = lib.mkEnableOption "Datomic Pro Console";
      package = lib.mkPackageOption pkgs "datomic-pro" { };
      javaPackage = lib.mkPackageOption pkgs "jdk-minimal" { };
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
      description = "Datomic Pro Console";
      wantedBy = [ "multi-user.target" ];
      script = ''
        db_uri="$(<"$CREDENTIALS_DIRECTORY/datomic-console-db-uri")"
        ${cfg.package}/bin/console -p ${toString cfg.port} "${cfg.alias}" "$db_uri"
      '';
      path = [ cfg.javaPackage ];
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
