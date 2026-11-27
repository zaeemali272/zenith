{ pkgs, vars, ... }:

{
  # Samba File Sharing (Disabled on startup)
  services.samba = {
    enable = false;
    openFirewall = false;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "NixOS Samba Server";
        "netbios name" = vars.hostname or "nixos";
        "security" = "user";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      "Samba" = {
        "path" = "/home/${vars.user}/Videos/Samba";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "public" = "yes";
        "writable" = "yes";
        "force user" = vars.user;
        "force group" = "users";
        "create mask" = "0664";
        "directory mask" = "0775";
      };
    };
  };

  # WSD for Windows network discovery (Disabled on startup)
  services.samba-wsdd = {
    enable = false;
    openFirewall = false;
  };
}
