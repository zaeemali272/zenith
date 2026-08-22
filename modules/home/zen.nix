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
    "full-screen-api.transition.timeout" = 0;
    "browser.sessionstore.restore_on_demand" = true;
    "browser.tabs.unloadOnLowMemory" = true;
  };

  extensions = [
    (extension "ublock-origin" "uBlock0@raymondhill.net")
    (extension "definition-dictionary-popup" "{22d3dc62-57d2-4f00-8bc4-ce0822e88c6e}")
    (extension "duckduckgo-for-firefox" "jid1-ZAdIEUB7XOzOJw@jetpack")
    (extension "mal-sync" "{c84d89d9-a826-4015-957b-affebd9eb603}")
    (extension "motrix-next-extension" "motrix-next-extension@aninsomniacy.dev")
  ];
in
{
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_WEBRENDER = "1";
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