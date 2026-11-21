{ pkgs, ... }: {
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    glances
    ncdu
    tree
    eza
    bat
    fzf
    zoxide
    fisher
    fastfetch
    krabby
    pokemon-colorscripts
    btop
    yazi
    github-cli
    claude-code
    yt-dlp
    proton-vpn-cli
    wireguard-tools
  ];
}
