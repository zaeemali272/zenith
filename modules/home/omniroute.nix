{ pkgs, config, lib, ... }:

let
  omniroutePkg = pkgs.symlinkJoin {
    name = "omniroute";
    paths = [
      (pkgs.writeShellScriptBin "omniroute" ''
        exec ${pkgs.nodejs_22}/bin/npx --yes omniroute@latest "$@"
      '')
      (pkgs.writeShellScriptBin "omniroute-reset-password" ''
        exec ${pkgs.nodejs_22}/bin/npx --yes omniroute@latest reset-password "$@"
      '')
    ];
  };
in
{
  options.services.omniroute = {
    enable = lib.mkEnableOption "OmniRoute AI gateway background service";
  };

  config = {
    home.packages = [ omniroutePkg ];

    systemd.user.services.omniroute = lib.mkIf config.services.omniroute.enable {
      Unit = {
        Description = "OmniRoute AI Gateway Service";
        After = [ "network.target" ];
      };
      Service = {
        ExecStart = "${omniroutePkg}/bin/omniroute";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
