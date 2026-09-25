{ pkgs, inputs, ... }:

{
  home.packages = [
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-ide
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli
    pkgs.libsecret
    pkgs.seahorse
  ];

  # Explicit secret storage configuration with basic file-backed store fallback
  home.sessionVariables = {
    PASSWORD_STORE = "gnome-libsecret";
    PYTHON_KEYRING_BACKEND = "keyring.backends.SecretService.Keyring";
  };
}
