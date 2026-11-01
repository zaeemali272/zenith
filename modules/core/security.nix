{ pkgs, ... }:

{
  security.polkit.enable = true;

  # Enable PAM gnome-keyring integration to automatically unlock keyring on login
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.zenith-lock.enableGnomeKeyring = true;

  # polkit itself is only the policy engine. Something has to actually show the
  # password dialog, and without an agent every privileged action from the
  # desktop fails silently -- pkexec has nowhere to ask, so it just returns an
  # error nobody sees. That is why toggling battery conservation from the shell
  # appeared to do nothing at all.
  # Application-level firewall (Rethink alternative for Linux)
  services.opensnitch.enable = true;

  environment.systemPackages = [
    pkgs.hyprpolkitagent
    pkgs.libsecret
    pkgs.seahorse
    pkgs.opensnitch-ui
  ];

  systemd.user.services.hyprpolkitagent = {
    description = "Hyprland polkit authentication agent";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
