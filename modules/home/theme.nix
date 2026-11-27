{ pkgs, lib, ... }:

{
  home.packages = [
    (pkgs.orchis-theme.override {
      tweaks = [ "black" ];
    })
    pkgs.adw-gtk3
    pkgs.reversal-icon-theme
    pkgs.bibata-cursors
    pkgs.gsettings-desktop-schemas
  ];

  home.sessionVariables = {
    GTK_THEME = lib.mkForce "Orchis-Dark";
    XCURSOR_THEME = lib.mkForce "Bibata-Modern-Classic";
    XCURSOR_SIZE = lib.mkForce "24";
  };

  gtk = {
    enable = true;
    theme = {
      name = lib.mkForce "Orchis-Dark";
      package = lib.mkForce (pkgs.orchis-theme.override {
        tweaks = [ "black" ];
      });
    };
    iconTheme = {
      name = lib.mkForce "Reversal-dark";
      package = lib.mkForce pkgs.reversal-icon-theme;
    };
    cursorTheme = {
      name = lib.mkForce "Bibata-Modern-Classic";
      package = lib.mkForce pkgs.bibata-cursors;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Orchis-Dark";
      icon-theme = "Reversal-dark";
      cursor-theme = "Bibata-Modern-Classic";
    };
  };

  xdg.configFile."caelestia/cli.json" = {
    text = builtins.toJSON {
      theme = {
        iconTheme = "Reversal-dark";
        iconThemeDark = "Reversal-dark";
        iconThemeLight = "Reversal";
      };
    };
    force = true;
  };

  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    enable = true;
    gtk.enable = true;
    x11.enable = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };
}
