{ pkgs, ... }: {
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    glances
    ncdu
    tree
    fastfetch
    btop
    yazi
    github-cli
    claude-code
    yt-dlp
  ];
}
