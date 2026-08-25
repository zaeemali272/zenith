{ pkgs, vars, ... }:

{
  users.users.${vars.user} = {
    isNormalUser = true;
    description = vars.fullName;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" "storage" "kvm" "libvirtd" "docker" ];
    shell = pkgs.fish;
  } // (if vars ? hashedPassword && vars.hashedPassword != "" then {
    hashedPassword = vars.hashedPassword;
  } else {
    initialPassword = "nixos";
  });

  services.getty.autologinUser = vars.user;
}
