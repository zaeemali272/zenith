{ vars, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = vars.fullName;
        email = vars.email;
      };
      # Tokens live in the GitHub CLI; `gituser <name>` picks which account
      # git pushes and pulls with.
      credential.helper = "!gh auth git-credential";
    };
  };
}
