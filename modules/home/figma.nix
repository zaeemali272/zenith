{ pkgs, ... }:

{
  home.packages = with pkgs; [
    figma-linux
    figma-agent
  ];

  # Run figma-agent in background to provide system fonts to Figma
  systemd.user.services.figma-agent = {
    Unit = {
      Description = "Figma Agent font helper daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.figma-agent}/bin/figma-agent";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Standalone Figma Web App launcher using Brave (persists login sessions permanently)
  xdg.desktopEntries.figma-app = {
    name = "Figma (Web App)";
    genericName = "Design Tool";
    comment = "Figma native web app with persistent session";
    exec = "${pkgs.brave-origin}/bin/brave-origin --app=https://www.figma.com %U";
    icon = "figma-linux";
    terminal = false;
    categories = [ "Graphics" "2DGraphics" ];
    mimeType = [ "x-scheme-handler/figma" ];
  };
}
