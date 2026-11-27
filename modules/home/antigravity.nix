{ pkgs, inputs, lib, ... }:

{
  home.packages = [
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-ide
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli
    pkgs.libsecret
    pkgs.seahorse
    pkgs.jq  # used by the activation script below
  ];

  # Secret storage + Electron/Wayland OAuth environment
  home.sessionVariables = {
    PASSWORD_STORE = "gnome-libsecret";
    PYTHON_KEYRING_BACKEND = "keyring.backends.SecretService.Keyring";

    # Let Electron use Wayland natively so the OAuth pop-up renders correctly
    ELECTRON_OZONE_PLATFORM_HINT = "auto";

    # Disable the Electron sandbox inside the FHS bubblewrap container;
    # the outer bubblewrap already sandboxes the process, and the inner
    # Chromium sandbox conflicts with it, breaking the OAuth redirect.
    ELECTRON_DISABLE_SANDBOX = "1";
  };

  # After every rebuild: ensure ~/.gemini/settings.json keeps google-account
  # as the auth type so Gemini models remain visible in the model picker.
  home.activation.antigravityGoogleAuth = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS="$HOME/.gemini/settings.json"
    mkdir -p "$(dirname "$SETTINGS")"

    if [ ! -f "$SETTINGS" ]; then
      echo '{"ide":{"hasSeenNudge":true},"security":{"auth":{"selectedType":"google-account"}}}' > "$SETTINGS"
    else
      # Only patch the selectedType field; leave everything else untouched.
      TMP=$(${pkgs.jq}/bin/jq '.security.auth.selectedType = "google-account"' "$SETTINGS") \
        && echo "$TMP" > "$SETTINGS"
    fi
  '';
}
