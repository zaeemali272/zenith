{ pkgs, vars, ... }:

{
  # Enable Samba File Sharing
  services.samba = {
    enable = true;
    openFirewall = true;
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

  # Enable WSD for Windows network discovery
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
