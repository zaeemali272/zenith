{ pkgs, ... }:

{
  programs.thunar = {
    enable = true;
    plugins = [
      pkgs.thunar-archive-plugin
      pkgs.thunar-volman
    ];
  };

  programs.xfconf.enable = true;
  services.tumbler.enable = true; 
  services.gvfs.enable = true;    

  # Declaratively configure Thunar settings via Xfconf XML backend
  environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/thunar.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="thunar" version="1.0">
      <property name="last-menubar-visible" type="bool" value="false"/>
    </channel>
  '';

  # Configure default TerminalEmulator for exo/thunar
  environment.etc."xdg/xfce4/helpers.rc".text = ''
    TerminalEmulator=kitty
  '';

  environment.etc."xdg/xfce4/helpers/kitty.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Icon=kitty
    Name=Kitty Terminal Emulator
    Type=X-XFCE-Helper
    X-XFCE-Category=TerminalEmulator
    X-XFCE-Commands=kitty
    X-XFCE-CommandsWithParameter=kitty --directory="%s"
  '';
}