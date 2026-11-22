{ pkgs, inputs, ... }:

{
  home.packages = [
    inputs.nectarlink.packages.${pkgs.stdenv.hostPlatform.system}.nectarlink
    pkgs.xclip
    pkgs.gst_all_1.gstreamer
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
    pkgs.gst_all_1.gst-plugins-bad
  ];

  # Autostart NectarLink minimized in the system tray on login [Disabled]
  # xdg.configFile."autostart/nectarlink.desktop".text = ''
  #   [Desktop Entry]
  #   Type=Application
  #   Version=1.5
  #   Name=NectarLink
  #   GenericName=Phone Link
  #   Comment=Connect your Android phone and Linux PC over LAN
  #   Exec=nectarlink-desktop --minimized
  #   Icon=nectarlink
  #   Terminal=false
  #   Categories=Network;FileTransfer;Telephony;
  #   StartupNotify=false
  #   X-GNOME-Autostart-enabled=true
  # '';
}
