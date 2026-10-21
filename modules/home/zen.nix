{
  inputs,
  pkgs,
  lib,
  ...
}:

let
  extension = shortId: guid: {
    name = guid;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "normal_installed";
    };
  };

  prefs = {
    "extensions.autoDisableScopes" = 0;
    "extensions.pocket.enabled" = false;
    "full-screen-api.allow-trusted-requests-only" = false;
    "full-screen-api.warning.timeout" = 0;
    "full-screen-api.warning.delay" = 0;
    "browser.sessionstore.restore_on_demand" = true;
    "browser.sessionstore.restore_tabs_lazily" = true;
    "browser.sessionstore.restore_pinned_tabs_on_demand" = true;
    "browser.tabs.unloadOnLowMemory" = true;
    "layers.acceleration.disabled" = false;
    "browser.preferences.defaultPerformanceSettings.enabled" = true;
    "gfx.webrender.all" = true;
    "gfx.webrender.compositor" = true;
    "media.ffmpeg.vaapi.enabled" = true;
    "media.hardware-video-decoding.enabled" = true;
    "media.rdd-ffmpeg.enabled" = true;
    "widget.use-aspect-ratio" = true;
    "accessibility.force_disabled" = 1;
  };

  extensions = [
    (extension "ublock-origin" "uBlock0@raymondhill.net")
    (extension "duckduckgo-for-firefox" "jid1-ZAdIEUB7XOzOJw@jetpack")
    (extension "mal-sync" "{c84d89d9-a826-4015-957b-affebd9eb603}")
    (extension "motrix-next-extension" "motrix-next-extension@aninsomniacy.dev")
  ];
in
{
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    LIBVA_DRIVER_NAME = "iHD";
  };

  home.packages = [
    (pkgs.wrapFirefox
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped
      {
        extraPrefs = lib.concatLines (
          lib.mapAttrsToList (
            name: value: ''lockPref(${lib.strings.toJSON name}, ${lib.strings.toJSON value});''
          ) prefs
        );

        extraPolicies = {
          DisableTelemetry = true;
          ExtensionSettings = builtins.listToAttrs extensions;

          SearchEngines = {
            Default = "DuckDuckGo";
            Add = [
              {
                Name = "nixpkgs packages";
                URLTemplate = "https://search.nixos.org/packages?query={searchTerms}";
                IconURL = "https://wiki.nixos.org/favicon.ico";
                Alias = "@np";
              }
            ];
          };
        };
      }
    )
  ];
}