{ pkgs, ... }: {
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    dua
    eza
    fzf
    zoxide
    fastfetch
    krabby
    github-cli
    claude-code
    yt-dlp
    proton-vpn-cli
    wireguard-tools
  ];
}
