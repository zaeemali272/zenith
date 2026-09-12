{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';

    functions = {
      # gituser <account>  - switch which GitHub account git uses from now on.
      #   gituser zaeem     -> zaeemali272 (personal)
      #   gituser zenova    -> ZENOVA-WEB
      # Sets the commit identity in the current repo (if in one) and makes
      # gh hand git that account's token for pushes and pulls.
      gituser = ''
        switch "$argv[1]"
          case zaeem zaeemali272
            set -l login zaeemali272; set -l name zaeem; set -l email zaeemali272@gmail.com
          case zenova zenovadevs ZENOVA-WEB
            set -l login ZENOVA-WEB; set -l name zenovadevs; set -l email zenovadevs@gmail.com
          case '*'
            echo "usage: gituser zaeem | zenova"; return 1
        end
        gh auth switch -h github.com -u $login; or return 1
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1
          git config user.name $name
          git config user.email $email
          echo "this repo now commits as $name <$email>"
        end
        echo "git now pushes/pulls as $login"
      '';
    };
  };
}
